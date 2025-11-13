// Main.mo - Main ticketing canister
import Types "./Types";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Option "mo:base/Option";
import Int "mo:base/Int";
import Blob "mo:base/Blob";
import Random "mo:base/Random";

shared(init_msg) actor class TicketingSystem(ledgerCanisterId : Principal) = this {
  
  // Stable storage
  private stable var nextEventId : Nat = 0;
  private stable var nextTicketId : Nat = 0;
  private stable var stableEvents : [(Nat, Types.Event)] = [];
  private stable var stableTickets : [(Nat, Types.Ticket)] = [];
  private stable var stableUserTickets : [(Principal, [Nat])] = [];
  private stable var stableEventRevenue : [(Nat, Nat)] = [];
  
  // Runtime state
  private var events = HashMap.HashMap<Nat, Types.Event>(10, Nat.equal, Hash.hash);
  private var tickets = HashMap.HashMap<Nat, Types.Ticket>(100, Nat.equal, Hash.hash);
  private var userTickets = HashMap.HashMap<Principal, Buffer.Buffer<Nat>>(10, Principal.equal, Principal.hash);
  private var eventRevenue = HashMap.HashMap<Nat, Nat>(10, Nat.equal, Hash.hash);
  
  // Constants
  private let TRANSFER_FEE : Nat = 10; // ckBTC transfer fee in e8s
  private let PLATFORM_FEE_PERCENT : Nat = 5; // 5% platform fee
  
  // ICRC-1 Ledger interface
  let Ledger : actor {
    icrc1_transfer : shared (Types.TransferArgs) -> async Types.TransferResult;
    icrc1_balance_of : shared query (Types.Account) -> async Nat;
    icrc2_approve : shared (Types.ApproveArgs) -> async Types.ApproveResult;
    icrc2_transfer_from : shared (Types.TransferFromArgs) -> async Types.TransferFromResult;
  } = actor(Principal.toText(ledgerCanisterId));

  // System upgrade hooks
  system func preupgrade() {
    stableEvents := Iter.toArray(events.entries());
    stableTickets := Iter.toArray(tickets.entries());
    stableUserTickets := Iter.toArray(
      Iter.map<(Principal, Buffer.Buffer<Nat>), (Principal, [Nat])>(
        userTickets.entries(),
        func(entry) { (entry.0, Buffer.toArray(entry.1)) }
      )
    );
    stableEventRevenue := Iter.toArray(eventRevenue.entries());
  };

  system func postupgrade() {
    for ((id, event) in stableEvents.vals()) {
      events.put(id, event);
    };
    for ((id, ticket) in stableTickets.vals()) {
      tickets.put(id, ticket);
    };
    for ((principal, ticketIds) in stableUserTickets.vals()) {
      let buffer = Buffer.Buffer<Nat>(ticketIds.size());
      for (id in ticketIds.vals()) {
        buffer.add(id);
      };
      userTickets.put(principal, buffer);
    };
    for ((id, revenue) in stableEventRevenue.vals()) {
      eventRevenue.put(id, revenue);
    };
    stableEvents := [];
    stableTickets := [];
    stableUserTickets := [];
    stableEventRevenue := [];
  };

  // Helper functions
  private func getUserTicketBuffer(user : Principal) : Buffer.Buffer<Nat> {
    switch (userTickets.get(user)) {
      case (?buffer) buffer;
      case null {
        let newBuffer = Buffer.Buffer<Nat>(10);
        userTickets.put(user, newBuffer);
        newBuffer;
      };
    };
  };

  private func generateQRCode(ticketId : Nat, eventId : Nat, time : Time.Time) : Text {
    // Simple QR code generation - in production, use a proper random generator
    let data = Nat.toText(ticketId) # "-" # Nat.toText(eventId) # "-" # Int.toText(time);
    // Hash the data for verification
    Text.hash(data) |> Nat.toText(_)
  };

  private func calculatePlatformFee(amount : Nat) : Nat {
    (amount * PLATFORM_FEE_PERCENT) / 100
  };

  // Public functions

  // Create a new event
  public shared(msg) func createEvent(args : Types.CreateEventArgs) : async Result.Result<Nat, Types.Error> {
    
    // Validation
    if (args.totalTickets == 0) {
      return #err(#InvalidInput("Total tickets must be greater than 0"));
    };
    if (args.pricePerTicket == 0) {
      return #err(#InvalidInput("Price per ticket must be greater than 0"));
    };
    if (args.date <= Time.now()) {
      return #err(#InvalidInput("Event date must be in the future"));
    };

    let eventId = nextEventId;
    nextEventId += 1;

    let event : Types.Event = {
      id = eventId;
      name = args.name;
      description = args.description;
      venue = args.venue;
      date = args.date;
      organizer = msg.caller;
      totalTickets = args.totalTickets;
      availableTickets = args.totalTickets;
      pricePerTicket = args.pricePerTicket;
      imageUrl = args.imageUrl;
      category = args.category;
      metadata = args.metadata;
      created = Time.now();
      status = #Active;
    };

    events.put(eventId, event);
    eventRevenue.put(eventId, 0);

    #ok(eventId)
  };

  // Purchase tickets
  public shared(msg) func purchaseTickets(args : Types.TicketPurchase) : async Types.PurchaseResult {
    
    // Get event
    let ?event = events.get(args.eventId) else {
      return #EventCancelled;
    };

    // Validation
    if (event.status != #Active) {
      return #EventCancelled;
    };
    if (args.quantity == 0 or args.quantity > 10) {
      return #InvalidQuantity;
    };
    if (event.availableTickets < args.quantity) {
      return #EventSoldOut;
    };

    let totalPrice = event.pricePerTicket * args.quantity;
    if (totalPrice != args.totalPrice) {
      return #PaymentFailed("Price mismatch");
    };

    // Calculate fees
    let platformFee = calculatePlatformFee(totalPrice);
    let organizerAmount = totalPrice - platformFee;

    // Transfer ckBTC from buyer to this canister
    // Buyer must have approved this canister first using icrc2_approve
    let transferFromArgs : Types.TransferFromArgs = {
      from = args.buyerAccount;
      to = { owner = Principal.fromActor(this); subaccount = null };
      amount = totalPrice;
      fee = ?TRANSFER_FEE;
      memo = ?Text.encodeUtf8("Ticket purchase: " # event.name);
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
    };

    let transferResult = await Ledger.icrc2_transfer_from(transferFromArgs);
    
    switch (transferResult) {
      case (#Err(e)) {
        return #PaymentFailed("Transfer failed: " # debug_show(e));
      };
      case (#Ok(blockIndex)) {
        // Payment successful, create tickets
        let purchasedTickets = Buffer.Buffer<Types.Ticket>(args.quantity);
        let now = Time.now();
        
        for (i in Iter.range(0, args.quantity - 1)) {
          let ticketId = nextTicketId;
          nextTicketId += 1;

          let ticket : Types.Ticket = {
            id = ticketId;
            eventId = args.eventId;
            owner = msg.caller;
            seatNumber = null; // Can be assigned later
            qrCode = generateQRCode(ticketId, args.eventId, now);
            purchased = now;
            used = false;
            usedAt = null;
            price = event.pricePerTicket;
            metadata = null;
            transferrable = true;
          };

          tickets.put(ticketId, ticket);
          purchasedTickets.add(ticket);
          
          let userBuffer = getUserTicketBuffer(msg.caller);
          userBuffer.add(ticketId);
        };

        // Update event availability
        let updatedEvent = {
          event with
          availableTickets = event.availableTickets - args.quantity;
          status = if (event.availableTickets - args.quantity == 0) #SoldOut else event.status;
        };
        events.put(args.eventId, updatedEvent);

        // Update revenue
        let currentRevenue = Option.get(eventRevenue.get(args.eventId), 0);
        eventRevenue.put(args.eventId, currentRevenue + totalPrice);

        // Transfer funds to organizer (minus platform fee)
        let organizerTransferArgs : Types.TransferArgs = {
          from_subaccount = null;
          to = { owner = event.organizer; subaccount = null };
          amount = organizerAmount;
          fee = ?TRANSFER_FEE;
          memo = ?Text.encodeUtf8("Ticket sales: " # event.name);
          created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        };

        ignore await Ledger.icrc1_transfer(organizerTransferArgs);

        #Success({
          tickets = Buffer.toArray(purchasedTickets);
          transactionId = blockIndex;
        })
      };
    };
  };

  // Verify and use a ticket
  public shared(msg) func verifyTicket(ticketId : Nat, qrCode : Text) : async Types.VerificationResult {
    
    let ?ticket = tickets.get(ticketId) else {
      return #Invalid("Ticket not found");
    };

    if (ticket.qrCode != qrCode) {
      return #Invalid("Invalid QR code");
    };

    if (ticket.used) {
      return #AlreadyUsed({ usedAt = Option.get(ticket.usedAt, 0) });
    };

    let ?event = events.get(ticket.eventId) else {
      return #Invalid("Event not found");
    };

    if (event.status == #Cancelled) {
      return #EventCancelled;
    };

    if (Time.now() < event.date) {
      return #EventNotStarted;
    };

    // Mark ticket as used
    let updatedTicket = {
      ticket with
      used = true;
      usedAt = ?Time.now();
    };
    tickets.put(ticketId, updatedTicket);

    #Valid({ ticket = updatedTicket; event = event })
  };

  // Transfer ticket to another user
  public shared(msg) func transferTicket(ticketId : Nat, newOwner : Principal) : async Result.Result<(), Types.Error> {
    
    let ?ticket = tickets.get(ticketId) else {
      return #err(#NotFound);
    };

    if (ticket.owner != msg.caller) {
      return #err(#Unauthorized);
    };

    if (not ticket.transferrable) {
      return #err(#InvalidInput("This ticket is not transferrable"));
    };

    if (ticket.used) {
      return #err(#InvalidInput("Cannot transfer used ticket"));
    };

    // Update ticket owner
    let updatedTicket = { ticket with owner = newOwner };
    tickets.put(ticketId, updatedTicket);

    // Update user ticket lists
    let senderBuffer = getUserTicketBuffer(msg.caller);
    let newSenderTickets = Buffer.Buffer<Nat>(senderBuffer.size());
    for (id in senderBuffer.vals()) {
      if (id != ticketId) {
        newSenderTickets.add(id);
      };
    };
    userTickets.put(msg.caller, newSenderTickets);

    let receiverBuffer = getUserTicketBuffer(newOwner);
    receiverBuffer.add(ticketId);

    #ok(())
  };

  // Cancel event (organizer only)
  public shared(msg) func cancelEvent(eventId : Nat) : async Result.Result<(), Types.Error> {
    
    let ?event = events.get(eventId) else {
      return #err(#NotFound);
    };

    if (event.organizer != msg.caller) {
      return #err(#Unauthorized);
    };

    let updatedEvent = { event with status = #Cancelled };
    events.put(eventId, updatedEvent);

    // TODO: Implement refund logic for ticket holders

    #ok(())
  };

  // Query functions

  public query func getEvent(eventId : Nat) : async ?Types.Event {
    events.get(eventId)
  };

  public query func getAllEvents() : async [Types.Event] {
    Iter.toArray(events.vals())
  };

  public query func getActiveEvents() : async [Types.Event] {
    let activeEvents = Buffer.Buffer<Types.Event>(events.size());
    for (event in events.vals()) {
      if (event.status == #Active and event.date > Time.now()) {
        activeEvents.add(event);
      };
    };
    Buffer.toArray(activeEvents)
  };

  public query func getTicket(ticketId : Nat) : async ?Types.Ticket {
    tickets.get(ticketId)
  };

  public query func getUserTickets(user : Principal) : async [Types.Ticket] {
    switch (userTickets.get(user)) {
      case null [];
      case (?buffer) {
        let userTicketsList = Buffer.Buffer<Types.Ticket>(buffer.size());
        for (ticketId in buffer.vals()) {
          switch (tickets.get(ticketId)) {
            case (?ticket) userTicketsList.add(ticket);
            case null {};
          };
        };
        Buffer.toArray(userTicketsList)
      };
    };
  };

  public query func getEventStats(eventId : Nat) : async ?Types.EventStats {
    let ?event = events.get(eventId) else {
      return null;
    };

    let ticketsSold = event.totalTickets - event.availableTickets;
    let revenue = Option.get(eventRevenue.get(eventId), 0);
    
    var ticketsUsed = 0;
    var uniqueBuyers = HashMap.HashMap<Principal, Bool>(10, Principal.equal, Principal.hash);
    
    for (ticket in tickets.vals()) {
      if (ticket.eventId == eventId) {
        if (ticket.used) ticketsUsed += 1;
        uniqueBuyers.put(ticket.owner, true);
      };
    };

    ?{
      eventId = eventId;
      totalRevenue = revenue;
      ticketsSold = ticketsSold;
      ticketsUsed = ticketsUsed;
      uniqueBuyers = uniqueBuyers.size();
    }
  };

  public query func getSystemStats() : async Types.SystemStats {
    var activeEvents = 0;
    var totalRevenue = 0;
    var totalTicketsSold = 0;

    for (event in events.vals()) {
      if (event.status == #Active and event.date > Time.now()) {
        activeEvents += 1;
      };
      totalTicketsSold += (event.totalTickets - event.availableTickets);
    };

    for (revenue in eventRevenue.vals()) {
      totalRevenue += revenue;
    };

    {
      totalEvents = events.size();
      totalTicketsSold = totalTicketsSold;
      totalRevenue = totalRevenue;
      activeEvents = activeEvents;
    }
  };

  // Helper types for ICRC compatibility
  type TransferArgs = {
    from_subaccount : ?Blob;
    to : Types.Account;
    amount : Nat;
    fee : ?Nat;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };

  type TransferResult = {
    #Ok : Nat;
    #Err : TransferError;
  };

  type TransferError = {
    #BadFee : { expected_fee : Nat };
    #BadBurn : { min_burn_amount : Nat };
    #InsufficientFunds : { balance : Nat };
    #TooOld;
    #CreatedInFuture : { ledger_time : Nat64 };
    #Duplicate : { duplicate_of : Nat };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };

  type ApproveArgs = {
    from_subaccount : ?Blob;
    spender : Types.Account;
    amount : Nat;
    expected_allowance : ?Nat;
    expires_at : ?Nat64;
    fee : ?Nat;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };

  type ApproveResult = {
    #Ok : Nat;
    #Err : ApproveError;
  };

  type ApproveError = {
    #BadFee : { expected_fee : Nat };
    #InsufficientFunds : { balance : Nat };
    #AllowanceChanged : { current_allowance : Nat };
    #Expired : { ledger_time : Nat64 };
    #TooOld;
    #CreatedInFuture : { ledger_time : Nat64 };
    #Duplicate : { duplicate_of : Nat };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };

  type TransferFromArgs = {
    from : Types.Account;
    to : Types.Account;
    amount : Nat;
    fee : ?Nat;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };

  type TransferFromResult = {
    #Ok : Nat;
    #Err : TransferFromError;
  };

  type TransferFromError = {
    #BadFee : { expected_fee : Nat };
    #BadBurn : { min_burn_amount : Nat };
    #InsufficientFunds : { balance : Nat };
    #InsufficientAllowance : { allowance : Nat };
    #TooOld;
    #CreatedInFuture : { ledger_time : Nat64 };
    #Duplicate : { duplicate_of : Nat };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };
}