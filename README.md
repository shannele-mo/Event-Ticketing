# 🎫 Event Ticketing System with ckBTC

A fully decentralized event ticketing platform built on the Internet Computer that uses ckBTC (chain-key Bitcoin) for ticket purchases. This system eliminates scalping bots, provides instant verification, and ensures transparent, tamper-proof ticket ownership.

## 🌟 Features

### Core Functionality
- **Create Events**: Organizers can create events with customizable details
- **Purchase Tickets**: Buy tickets using ckBTC with instant confirmation
- **NFT Tickets**: Each ticket is a unique, verifiable NFT
- **QR Code Verification**: Secure ticket validation at event entry
- **Transfer Tickets**: Send tickets to friends (when transferrable)
- **Anti-Scalping**: Built-in mechanisms to prevent bot purchases
- **Refunds**: Automatic refunds if events are cancelled

### Payment Features
- **ckBTC Integration**: Real Bitcoin payments with 1-2 second finality
- **ICRC-2 Standard**: Uses approve + transfer_from workflow
- **Low Fees**: ~$0.00001 per transaction
- **Platform Fee**: 5% fee for platform maintenance
- **Direct Payouts**: Organizers receive funds instantly

### Security Features
- **Internet Identity**: Secure authentication without passwords
- **No Scalping Bots**: Rate limiting and human verification
- **Immutable Records**: All transactions on-chain
- **Unique QR Codes**: Each ticket has a cryptographically secure code
- **Usage Tracking**: Prevents ticket reuse

## 📁 Project Structure

```
event-ticketing/
├── src/
│   ├── ticketing_backend/
│   │   ├── Main.mo           # Main ticketing canister
│   │   └── Types.mo          # Type definitions
│   └── ticketing_frontend/   # React frontend (optional)
├── dfx.json                  # Canister configuration
├── deploy.sh                 # Deployment script
└── README.md                 # This file
```

## 🚀 Quick Start

### Prerequisites
- Install [dfx](https://internetcomputer.org/docs/current/developer-docs/setup/install/) (IC SDK)
- Install [Node.js](https://nodejs.org/) (for frontend)
- Install [mops](https://mops.one/) (Motoko package manager)

### Installation

1. **Clone or create the project**
```bash
mkdir event-ticketing && cd event-ticketing
```

2. **Create the file structure**
```bash
mkdir -p src/ticketing_backend
# Add the Main.mo and Types.mo files to src/ticketing_backend/
```

3. **Make deployment script executable**
```bash
chmod +x deploy.sh
```

4. **Deploy the system**
```bash
./deploy.sh
```

This will:
- Start a local IC replica
- Deploy Internet Identity
- Deploy the ckBTC ledger (local test version)
- Deploy the index canister
- Deploy the ticketing backend
- Provide you with canister IDs and sample commands

## 💡 Usage Examples

### For Event Organizers

#### 1. Create an Event
```bash
dfx canister call ticketing_backend createEvent '(record {
  name = "Bitcoin Conference 2025";
  description = "Annual Bitcoin developers conference";
  venue = "Convention Center, San Francisco";
  date = 1735689600000000000; # Unix timestamp in nanoseconds
  totalTickets = 500;
  pricePerTicket = 50000000; # 0.5 ckBTC (50 million e8s)
  imageUrl = opt "https://example.com/btc-conf.jpg";
  category = variant { Conference };
  metadata = null;
})'
```

#### 2. Check Event Stats
```bash
dfx canister call ticketing_backend getEventStats '(0)'
```

#### 3. Cancel an Event (if needed)
```bash
dfx canister call ticketing_backend cancelEvent '(0)'
```

### For Ticket Buyers

#### 1. Check Available Events
```bash
dfx canister call ticketing_backend getActiveEvents '()'
```

#### 2. Approve ckBTC Spending
Before purchasing, approve the ticketing canister to spend your ckBTC:
```bash
TICKETING_ID=$(dfx canister id ticketing_backend)
dfx canister call icrc1_ledger_canister icrc2_approve "(record {
  spender = record { owner = principal \"${TICKETING_ID}\"; };
  amount = 100000000; # Amount you want to authorize
})"
```

#### 3. Purchase Tickets
```bash
BUYER=$(dfx identity get-principal)
dfx canister call ticketing_backend purchaseTickets "(record {
  eventId = 0;
  quantity = 2;
  buyerAccount = record { owner = principal \"${BUYER}\"; subaccount = null };
  totalPrice = 100000000; # 2 tickets × 0.5 ckBTC
})"
```

#### 4. View Your Tickets
```bash
dfx canister call ticketing_backend getUserTickets "(principal \"${BUYER}\")"
```

#### 5. Transfer a Ticket
```bash
FRIEND=$(dfx identity get-principal --identity friend)
dfx canister call ticketing_backend transferTicket "(0, principal \"${FRIEND}\")"
```

### For Event Staff

#### Verify Ticket at Entry
```bash
dfx canister call ticketing_backend verifyTicket '(0, "unique-qr-code-hash")'
```

## 🔧 Technical Details

### ckBTC Integration

The system uses ICRC-2 (approve + transfer_from) workflow:

1. **User approves** the ticketing canister to spend ckBTC
2. **User calls** `purchaseTickets` function
3. **Canister pulls** ckBTC from user's account
4. **Canister distributes** funds (95% to organizer, 5% platform fee)
5. **Canister mints** NFT tickets for the user

### Price Format
All prices are in **e8s** (satoshis):
- 1 ckBTC = 100,000,000 e8s
- 0.5 ckBTC = 50,000,000 e8s
- 0.01 ckBTC = 1,000,000 e8s

### Anti-Scalping Mechanisms

1. **Quantity Limits**: Max 10 tickets per transaction
2. **Rate Limiting**: Prevents rapid bulk purchases
3. **Identity Verification**: Internet Identity required
4. **Transferrable Flag**: Organizers can disable resale
5. **On-chain Records**: All purchases are transparent

### Ticket Verification

Each ticket contains:
- Unique ticket ID
- Event ID
- Owner principal
- Cryptographic QR code
- Purchase timestamp
- Usage status

QR codes are generated using:
```
QR = Hash(ticketId + eventId + timestamp)
```

## 🌐 Mainnet Deployment

### Using Real ckBTC

1. **Update dfx.json** to use mainnet ckBTC ledger:
```json
{
  "canisters": {
    "ticketing_backend": {
      "main": "src/ticketing_backend/Main.mo",
      "type": "motoko",
      "dependencies": ["icrc1_ledger_canister"]
    }
  },
  "networks": {
    "ic": {
      "providers": ["https://ic0.app"],
      "type": "persistent"
    }
  }
}
```

2. **Deploy to mainnet**:
```bash
dfx deploy --network ic ticketing_backend \
  --argument 'principal "mxzaz-hqaaa-aaaar-qaada-cai"'
```

Note: `mxzaz-hqaaa-aaaar-qaada-cai` is the mainnet ckBTC ledger canister ID.

### Get Real ckBTC

Users can get real ckBTC by:
1. Visiting the [NNS dapp](https://nns.ic0.app)
2. Sending Bitcoin to their ICP address
3. Converting BTC to ckBTC (1:1 ratio)

## 📊 Platform Economics

### Revenue Model
- **Platform Fee**: 5% of ticket sales
- **Transfer Fee**: Minimal ckBTC network fee (~$0.00001)
- **Organizer Payout**: 95% of ticket sales (instant)

### Example Transaction
- Ticket Price: 1.0 ckBTC
- Platform Fee: 0.05 ckBTC (5%)
- Organizer Receives: 0.95 ckBTC
- Transfer Fee: ~0.0000001 ckBTC

## 🔐 Security Best Practices

1. **Always verify** event details before purchasing
2. **Double-check** QR codes at event entry
3. **Never share** your QR code publicly before the event
4. **Keep your Internet Identity** secure
5. **Verify transaction** amounts before approving

## 🛠️ Development

### Running Tests
```bash
# Unit tests
mops test

# Integration tests
dfx canister call ticketing_backend test_suite '()'
```

### Local Development
```bash
# Start local replica
dfx start --clean

# Deploy locally
./deploy.sh

# Watch for changes (if using frontend)
npm run dev
```

## 🐛 Troubleshooting

### "Insufficient Funds" Error
- Check your ckBTC balance: `dfx canister call icrc1_ledger_canister icrc1_balance_of ...`
- Ensure you've approved enough ckBTC for purchase + fees

### "Insufficient Allowance" Error
- Call `icrc2_approve` again with sufficient amount
- Remember to include transfer fees in approval

### "Event Not Found" Error
- Verify the event ID exists
- Check if event was cancelled

### Ticket Transfer Failed
- Ensure ticket is transferrable
- Verify you own the ticket
- Check that ticket hasn't been used

## 📚 Additional Resources

- [Internet Computer Documentation](https://internetcomputer.org/docs)
- [ckBTC Integration Guide](https://internetcomputer.org/docs/references/bitcoin-how-it-works)
- [ICRC-1 Token Standard](https://github.com/dfinity/ICRC-1)
- [ICRC-2 Approve Workflow](https://github.com/dfinity/ICRC-1/blob/main/standards/ICRC-2/README.md)
- [Motoko Language Guide](https://internetcomputer.org/docs/motoko/main/about-this-guide)

## 🤝 Contributing

Contributions are welcome! Areas for improvement:
- Frontend interface
- Secondary marketplace
- Email notifications
- SMS verification
- Social features
- Analytics dashboard
- Mobile app

## 📄 License

MIT License - feel free to use and modify for your projects!

## 🎯 Roadmap

- [ ] Secondary ticket marketplace
- [ ] Dynamic pricing algorithms
- [ ] Multi-currency support (ckETH, ckUSDC)
- [ ] Loyalty programs
- [ ] Event recommendations
- [ ] Mobile app (iOS/Android)
- [ ] Integration with physical venues
- [ ] NFT collectibles for attendees

---

**Built with ❤️ on the Internet Computer**

Questions? Open an issue or reach out to the ICP developer community!