// Types.mo - Data types for the ticketing system
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Blob "mo:base/Blob";

module Types {

  // Main data structures
  public type Event = {
    id : Nat;
    name : Text;
    description : Text;
    venue : Text;
    date : Time.Time;
    organizer : Principal;
    totalTickets : Nat;
    availableTickets : Nat;
    pricePerTicket : Nat;
    imageUrl : ?Text;
    category : ?Text;
    metadata : ?[(Text, Text)];
    created : Time.Time;
    status : EventStatus;
  };

  public type Ticket = {
    id : Nat;
    eventId : Nat;
    owner : Principal;
    seatNumber : ?Text;
    qrCode : Text;
    purchased : Time.Time;
    used : Bool;
    usedAt : ?Time.Time;
    price : Nat;
    metadata : ?[(Text, Text)];
    transferrable : Bool;
  };

  // Enums
  public type EventStatus = {
    #Active;
    #SoldOut;
    #Cancelled;
    #Completed;
  };

  // Function argument types
  public type CreateEventArgs = {
    name : Text;
    description : Text;
    venue : Text;
    date : Time.Time;
    totalTickets : Nat;
    pricePerTicket : Nat;
    imageUrl : ?Text;
    category : ?Text;
    metadata : ?[(Text, Text)];
  };

  public type TicketPurchase = {
    eventId : Nat;
    quantity : Nat;
    totalPrice : Nat;
    buyerAccount : Account;
  };

  // Function result types
  public type PurchaseResult = {
    #Success : { tickets : [Ticket]; transactionId : Nat };
    #EventSoldOut;
    #EventCancelled;
    #InvalidQuantity;
    #PaymentFailed : Text;
  };

  public type Account = {
    owner : Principal;
    subaccount : ?Blob;
  };

  public type Error = {
    #NotFound;
    #Unauthorized;
    #InvalidInput : Text;
  };

  public type VerificationResult = {
    #Valid : { ticket : Ticket; event : Event };
    #Invalid : Text;
    #AlreadyUsed : { usedAt : Time.Time };
    #EventNotStarted;
    #EventCancelled;
  };

  // Statistics types
  public type EventStats = {
    eventId : Nat;
    totalRevenue : Nat;
    ticketsSold : Nat;
    ticketsUsed : Nat;
    uniqueBuyers : Nat;
  };

  public type SystemStats = {
    totalEvents : Nat;
    totalTicketsSold : Nat;
    totalRevenue : Nat;
    activeEvents : Nat;
  };

  // ICRC-1 Types
  public type TransferArgs = {
    from_subaccount : ?Blob;
    to : Account;
    amount : Nat;
    fee : ?Nat;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };

  public type TransferResult = {
    #Ok : Nat;
    #Err : TransferError;
  };

  public type TransferError = {
    #BadFee : { expected_fee : Nat };
    #BadBurn : { min_burn_amount : Nat };
    #InsufficientFunds : { balance : Nat };
    #TooOld;
    #CreatedInFuture : { ledger_time : Nat64 };
    #Duplicate : { duplicate_of : Nat };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };

  // ICRC-2 Types
  public type ApproveArgs = {
    from_subaccount : ?Blob;
    spender : Account;
    amount : Nat;
    expected_allowance : ?Nat;
    expires_at : ?Nat64;
    fee : ?Nat;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };

  public type ApproveResult = {
    #Ok : Nat;
    #Err : ApproveError;
  };

  public type ApproveError = {
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

  public type TransferFromArgs = {
    from : Account;
    to : Account;
    amount : Nat;
    fee : ?Nat;
    memo : ?Blob;
    created_at_time : ?Nat64;
  };

  public type TransferFromResult = {
    #Ok : Nat;
    #Err : TransferFromError;
  };

  public type TransferFromError = {
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
};
