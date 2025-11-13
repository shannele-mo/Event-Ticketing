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
};
