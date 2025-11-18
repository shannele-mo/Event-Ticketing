# 🧪 Testing Guide for Event Ticketing System

This guide walks you through testing the complete event ticketing system with ckBTC integration.

## 🎬 Complete Test Scenario

### Setup Phase

#### 1. Deploy the System
```bash
./deploy.sh
```

Save the canister IDs that are displayed:
```bash
export LEDGER_ID="mxzaz-hqaaa-aaaar-qaada-cai"
export TICKETING_ID="<your-ticketing-canister-id>"
export OWNER=$(dfx identity get-principal)
```

#### 2. Create Test Identities
```bash
# Create organizer identity
dfx identity new organizer
dfx identity use organizer
export ORGANIZER=$(dfx identity get-principal)

# Create buyer identities
dfx identity new alice
dfx identity use alice
export ALICE=$(dfx identity get-principal)

dfx identity new bob
dfx identity use bob
export BOB=$(dfx identity get-principal)

# Back to default
dfx identity use default
```

#### 3. Fund Test Accounts
```bash
# Mint ckBTC to Alice (10 ckBTC)
dfx canister call icrc1_ledger_canister icrc1_transfer "(record {
  to = record { owner = principal \"${ALICE}\"; };
  amount = 1_000_000_000;
})"

# Mint ckBTC to Bob (5 ckBTC)
dfx canister call icrc1_ledger_canister icrc1_transfer "(record {
  to = record { owner = principal \"${BOB}\"; };
  amount = 500_000_000;
})"

# Verify balances
dfx canister call icrc1_ledger_canister icrc1_balance_of "(record { owner = principal \"${ALICE}\"; })"
dfx canister call icrc1_ledger_canister icrc1_balance_of "(record { owner = principal \"${BOB}\"; })"
```

---

## 🎪 Test 1: Create Event

### As Organizer
```bash
dfx identity use organizer

# Create a concert event
dfx canister call ticketing_backend createEvent '(record {
  name = "ICP Developer Meetup 2025";
  description = "Meet fellow ICP developers, share projects, and network";
  venue = "Tech Hub, Nairobi";
  date = 1750000000000000000;
  totalTickets = 100;
  pricePerTicket = 50_000_000;
  imageUrl = opt "https://example.com/meetup.jpg";
  category = variant { Conference };
  metadata = null;
})'
```

**Expected Output:**
```
(variant { ok = 0 : nat })
```

### Verify Event Creation
```bash
dfx canister call ticketing_backend getEvent '(0)'
```

**Expected Output:**
```motoko
(
  opt record {
    id = 0;
    name = "ICP Developer Meetup 2025";
    status = variant { Active };
    availableTickets = 100;
    pricePerTicket = 50_000_000;
    // ... other fields
  }
)
```

### Create Multiple Events
```bash
# Sports event
dfx canister call ticketing_backend createEvent '(record {
  name = "Football Championship Final";
  description = "Epic final match";
  venue = "National Stadium";
  date = 1755000000000000000;
  totalTickets = 500;
  pricePerTicket = 100_000_000;
  imageUrl = opt "https://example.com/football.jpg";
  category = variant { Sports };
  metadata = null;
})'

# Comedy show
dfx canister call ticketing_backend createEvent '(record {
  name = "Comedy Night Extravaganza";
  description = "Laugh until you cry";
  venue = "Comedy Club Downtown";
  date = 1752000000000000000;
  totalTickets = 50;
  pricePerTicket = 30_000_000;
  imageUrl = opt "https://example.com/comedy.jpg";
  category = variant { Comedy };
  metadata = null;
})'
```

### View All Events
```bash
dfx canister call ticketing_backend getActiveEvents '()'
```

---

## 🎟️ Test 2: Purchase Tickets

### As Alice - Purchase for Event 0

#### Step 1: Approve ckBTC Spending
```bash
dfx identity use alice

# Approve ticketing canister to spend 1 ckBTC
dfx canister call icrc1_ledger_canister icrc2_approve "(record {
  spender = record { owner = principal \"${TICKETING_ID}\"; };
  amount = 100_000_000;
  fee = opt 10;
})"
```

**Expected Output:**
```
(variant { Ok = 1 : nat })
```

#### Step 2: Purchase 2 Tickets
```bash
dfx canister call ticketing_backend purchaseTickets "(record {
  eventId = 0;
  quantity = 2;
  buyerAccount = record { owner = principal \"${ALICE}\"; subaccount = null };
  totalPrice = 100_000_000;
})"
```

**Expected Output:**
```motoko
(
  variant {
    Success = record {
      transactionId = 2 : nat;
      tickets = vec {
        record {
          id = 0;
          eventId = 0;
          owner = principal "alice-principal";
          qrCode = "hash-value";
          used = false;
          price = 50_000_000;
        };
        record {
          id = 1;
          eventId = 0;
          owner = principal "alice-principal";
          qrCode = "hash-value-2";
          used = false;
          price = 50_000_000;
        };
      };
    }
  }
)
```

#### Step 3: Verify Purchase
```bash
# Check Alice's tickets
dfx canister call ticketing_backend getUserTickets "(principal \"${ALICE}\")"

# Check Alice's remaining ckBTC balance
dfx canister call icrc1_ledger_canister icrc1_balance_of "(record { owner = principal \"${ALICE}\"; })"

# Check event availability
dfx canister call ticketing_backend getEvent '(0)'
```

**Expected:** Alice should have 2 tickets, ~0.9 ckBTC remaining, event should have 98 available tickets.

### As Bob - Purchase for Event 1

```bash
dfx identity use bob

# Approve spending
dfx canister call icrc1_ledger_canister icrc2_approve "(record {
  spender = record { owner = principal \"${TICKETING_ID}\"; };
  amount = 200_000_000;
})"

# Purchase 1 ticket for football event
dfx canister call ticketing_backend purchaseTickets "(record {
  eventId = 1;
  quantity = 1;
  buyerAccount = record { owner = principal \"${BOB}\"; subaccount = null };
  totalPrice = 100_000_000;
})"

# Check Bob's tickets
dfx canister call ticketing_backend getUserTickets "(principal \"${BOB}\")"
```

---

## 🎭 Test 3: Ticket Transfer

### Transfer Ticket from Alice to Bob

```bash
dfx identity use alice

# Get Alice's ticket ID (use ID from previous output, e.g., 0)
ALICE_TICKET_ID=0

# Transfer ticket to Bob
dfx canister call ticketing_backend transferTicket "(${ALICE_TICKET_ID}, principal \"${BOB}\")"
```

**Expected Output:**
```
(variant { ok })
```

### Verify Transfer
```bash
# Check Alice's tickets (should have 1 now)
dfx canister call ticketing_backend getUserTickets "(principal \"${ALICE}\")"

# Check Bob's tickets (should have 2 now)
dfx canister call ticketing_backend getUserTickets "(principal \"${BOB}\")"

# Check specific ticket ownership
dfx canister call ticketing_backend getTicket "(${ALICE_TICKET_ID})"
```

**Expected:** Ticket should now show Bob as owner.

---

## ✅ Test 4: Ticket Verification

### Verify Valid Ticket at Event Entry

```bash
dfx identity use default # Event staff

# Get a ticket's QR code first
dfx canister call ticketing_backend getTicket '(1)' | grep qrCode

# Use the QR code to verify (replace with actual QR code)
dfx canister call ticketing_backend verifyTicket '(1, "actual-qr-code-hash")'
```

**Expected Output (First Time):**
```motoko
(
  variant {
    Valid = record {
      ticket = record { id = 1; used = true; /* ... */ };
      event = record { id = 0; name = "ICP Developer Meetup 2025"; /* ... */ };
    }
  }
)
```

### Try to Use Same Ticket Again

```bash
dfx canister call ticketing_backend verifyTicket '(1, "actual-qr-code-hash")'
```

**Expected Output:**
```motoko
(
  variant {
    AlreadyUsed = record { usedAt = 1700000000000000000 : nat64 }
  }
)
```

### Try Invalid QR Code

```bash
dfx canister call ticketing_backend verifyTicket '(1, "wrong-qr-code")'
```

**Expected Output:**
```motoko
(variant { Invalid = "Invalid QR code" })
```

---

## 📊 Test 5: Statistics and Analytics

### Check Event Statistics

```bash
dfx identity use organizer

# Get stats for event 0
dfx canister call ticketing_backend getEventStats '(0)'
```

**Expected Output:**
```motoko
(
  opt record {
    eventId = 0;
    totalRevenue = 100_000_000;
    ticketsSold = 2;
    ticketsUsed = 1;
    uniqueBuyers = 1;
  }
)
```

### Check System-Wide Statistics

```bash
dfx canister call ticketing_backend getSystemStats '()'
```

**Expected Output:**
```motoko
(
  record {
    totalEvents = 3;
    totalTicketsSold = 3;
    totalRevenue = 200_000_000;
    activeEvents = 3;
  }
)
```

---

## ❌ Test 6: Error Handling

### Test 6.1: Insufficient Funds

```bash
dfx identity use bob

# Bob only has ~4 ckBTC left
# Try to buy 100 tickets (would cost 50 ckBTC)
dfx canister call ticketing_backend purchaseTickets "(record {
  eventId = 1;
  quantity = 100;
  buyerAccount = record { owner = principal \"${BOB}\"; subaccount = null };
  totalPrice = 10_000_000_000;
})"
```

**Expected:** Error about insufficient funds or allowance.

### Test 6.2: Quantity Validation

```bash
# Try to buy 0 tickets
dfx canister call ticketing_backend purchaseTickets "(record {
  eventId = 0;
  quantity = 0;
  buyerAccount = record { owner = principal \"${BOB}\"; subaccount = null };
  totalPrice = 0;
})"
```

**Expected:** `InvalidQuantity` error.

```bash
# Try to buy more than 10 tickets
dfx canister call ticketing_backend purchaseTickets "(record {
  eventId = 0;
  quantity = 15;
  buyerAccount = record { owner = principal \"${BOB}\"; subaccount = null };
  totalPrice = 750_000_000;
})"
```

**Expected:** `InvalidQuantity` error.

### Test 6.3: Unauthorized Event Cancellation

```bash
dfx identity use alice # Not the organizer

# Try to cancel event
dfx canister call ticketing_backend cancelEvent '(0)'
```

**Expected:** `Unauthorized` error.

### Test 6.4: Transfer Used Ticket

```bash
dfx identity use bob

# Try to transfer a used ticket (ticket 1 was already used)
dfx canister call ticketing_backend transferTicket "(1, principal \"${ALICE}\")"
```

**Expected:** Error about transferring used ticket.

---

## 🔥 Test 7: Event Cancellation

### Cancel Event as Organizer

```bash
dfx identity use organizer

# Cancel event 2 (Comedy Night)
dfx canister call ticketing_backend cancelEvent '(2)'
```

**Expected Output:**
```
(variant { ok })
```

### Verify Cancellation

```bash
# Check event status
dfx canister call ticketing_backend getEvent '(2)'
```

**Expected:** Event status should be `Cancelled`.

### Try to Purchase Cancelled Event Tickets

```bash
dfx identity use alice

dfx canister call ticketing_backend purchaseTickets "(record {
  eventId = 2;
  quantity = 1;
  buyerAccount = record { owner = principal \"${ALICE}\"; subaccount = null };
  totalPrice = 30_000_000;
})"
```

**Expected:** `EventCancelled` error.

---

## 🔄 Test 8: High-Volume Scenario

### Simulate Multiple Buyers

```bash
# Create multiple buyers
for i in {1..5}; do
  dfx identity new buyer$i
  BUYER=$(dfx identity get-principal --identity buyer$i)
  
  # Fund each buyer with 1 ckBTC
  dfx identity use default
  dfx canister call icrc1_ledger_canister icrc1_transfer "(record {
    to = record { owner = principal \"${BUYER}\"; };
    amount = 100_000_000;
  })"
  
  # Each buyer purchases tickets
  dfx identity use buyer$i
  dfx canister call icrc1_ledger_canister icrc2_approve "(record {
    spender = record { owner = principal \"${TICKETING_ID}\"; };
    amount = 100_000_000;
  })"
  
  dfx canister call ticketing_backend purchaseTickets "(record {
    eventId = 0;
    quantity = 1;
    buyerAccount = record { owner = principal \"${BUYER}\"; subaccount = null };
    totalPrice = 50_000_000;
  })"
done

# Check event availability
dfx canister call ticketing_backend getEvent '(0)'
```

**Expected:** Event should show reduced availability.

---

## 📋 Test Checklist

Use this checklist to ensure all tests pass:

- [ ] System deploys successfully
- [ ] Events can be created
- [ ] Multiple events display correctly
- [ ] ckBTC approval works
- [ ] Ticket purchase succeeds
- [ ] Buyer receives correct number of tickets
- [ ] Event availability updates correctly
- [ ] Organizer receives payment (minus platform fee)
- [ ] Tickets can be transferred
- [ ] Ticket ownership updates after transfer
- [ ] Valid tickets verify correctly
- [ ] Used tickets cannot be reused
- [ ] Invalid QR codes are rejected
- [ ] Event statistics are accurate
- [ ] System statistics are correct
- [ ] Insufficient funds error works
- [ ] Quantity validation works
- [ ] Unauthorized actions are blocked
- [ ] Used tickets cannot be transferred
- [ ] Event cancellation works
- [ ] Cancelled events block purchases
- [ ] High-volume purchases work

---

## 🐛 Common Issues and Solutions

### Issue: "Insufficient Allowance"
**Solution:** Call `icrc2_approve` with sufficient amount before purchase.

### Issue: "Payment Failed"
**Solution:** Ensure you have enough ckBTC balance + transfer fees.

### Issue: "Invalid QR Code"
**Solution:** Get the exact QR code string from the ticket using `getTicket`.

### Issue: Canister Out of Cycles
**Solution:** Top up the canister with cycles:
```bash
dfx ledger fabricate-cycles --canister ticketing_backend
```

---

## 🎯 Performance Benchmarks

Expected performance:
- Event creation: < 1 second
- Ticket purchase: 2-3 seconds (includes ckBTC transfer)
- Ticket verification: < 500ms (query call)
- Transfer ticket: ~1 second
- Statistics queries: < 100ms

---

## 📈 Next Steps

After successful testing:
1. Deploy to mainnet using real ckBTC
2. Integrate with a frontend UI
3. Add email/SMS notifications
4. Implement secondary marketplace
5. Add analytics dashboard
6. Integrate with physical venue scanners

---

**Happy Testing! 🎉**