// Types.mo - Data types for the ticketing system
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";

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
    subaccount : ?[Nat8];
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
};
