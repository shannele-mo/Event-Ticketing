#!/bin/bash

# Event Ticketing System Deployment Script
# This script deploys the complete ticketing system with ckBTC integration

set -e

echo "🎫 Deploying Event Ticketing System with ckBTC"
echo "==============================================="

# Start dfx in the background if not already running
echo "Starting local IC replica..."
dfx start --clean --background

# Get principals
export OWNER=$(dfx identity get-principal)
export MINTER=$(dfx identity get-principal)

echo "Owner Principal: $OWNER"
echo "Minter Principal: $MINTER"

# Deploy Internet Identity for authentication
echo ""
echo "📱 Deploying Internet Identity..."
dfx deploy internet_identity

# Deploy ICRC-1 Ledger (Local ckBTC for testing)
echo ""
echo "💰 Deploying ICRC-1 Ledger (ckBTC)..."
dfx deploy --specified-id mxzaz-hqaaa-aaaar-qaada-cai icrc1_ledger_canister --argument "
  (variant {
    Init = record {
      token_name = \"Local ckBTC\";
      token_symbol = \"LCKBTC\";
      minting_account = record {
        owner = principal \"${MINTER}\";
      };
      initial_balances = vec {
        record {
          record {
            owner = principal \"${OWNER}\";
          };
          100_000_000_000;
        };
      };
      metadata = vec {};
      transfer_fee = 10;
      archive_options = record {
        trigger_threshold = 2000;
        num_blocks_to_archive = 1000;
        controller_id = principal \"${OWNER}\";
      };
      feature_flags = opt record {
        icrc2 = true;
      };
    }
  })
"

# Get ledger canister ID
export LEDGER_ID=$(dfx canister id icrc1_ledger_canister)
echo "Ledger Canister ID: $LEDGER_ID"

# Deploy Index Canister
echo ""
echo "📊 Deploying ICRC-1 Index Canister..."
dfx deploy icrc1_index_canister --argument "
  record {
    ledger_id = principal \"${LEDGER_ID}\";
  }
"

# Deploy Ticketing Backend
echo ""
echo "🎟️ Deploying Ticketing Backend..."
dfx deploy ticketing_backend --argument "principal \"${LEDGER_ID}\""

export TICKETING_ID=$(dfx canister id ticketing_backend)
echo "Ticketing Canister ID: $TICKETING_ID"

# Deploy Frontend
echo ""
echo "🌐 Deploying Ticketing Frontend..."
dfx deploy ticketing_frontend

echo ""
echo "✅ Deployment Complete!"
echo "======================="
echo ""
echo "Canister IDs:"
echo "  Internet Identity: $(dfx canister id internet_identity)"
echo "  ckBTC Ledger:      $LEDGER_ID"
echo "  Index Canister:    $(dfx canister id icrc1_index_canister)"
echo "  Ticketing Backend: $TICKETING_ID"
echo "  Ticketing Frontend: $(dfx canister id ticketing_frontend)"
echo ""
echo "Frontend URL: http://$(dfx canister id ticketing_frontend).localhost:4943"
echo ""
echo "🎉 You can now create events and sell tickets with ckBTC!"
echo ""
echo "Sample Commands:"
echo "================"
echo ""
echo "# Check your ckBTC balance:"
echo "dfx canister call icrc1_ledger_canister icrc1_balance_of '(record { owner = principal \"${OWNER}\"; })'"
echo ""
echo "# Create a sample event:"
echo "dfx canister call ticketing_backend createEvent '(record {
  name = \"Rock Concert 2025\";
  description = \"Amazing rock concert with live bands\";
  venue = \"Central Stadium\";
  date = 1735689600000000000;
  totalTickets = 1000;
  pricePerTicket = 100000000;
  imageUrl = opt \"https://example.com/concert.jpg\";
  category = variant { Concert };
  metadata = null;
})'"
echo ""
echo "# Get all active events:"
echo "dfx canister call ticketing_backend getActiveEvents '()'"
echo ""
echo "# Approve ticketing canister to spend your ckBTC (required before purchase):"
echo "dfx canister call icrc1_ledger_canister icrc2_approve '(record {
  spender = record { owner = principal \"${TICKETING_ID}\"; };
  amount = 1000000000;
})'"
echo ""
echo "# Purchase tickets:"
echo "dfx canister call ticketing_backend purchaseTickets '(record {
  eventId = 0;
  quantity = 2;
  buyerAccount = record { owner = principal \"${OWNER}\"; subaccount = null };
  totalPrice = 200000000;
})'"
echo ""
echo "# Get your tickets:"
echo "dfx canister call ticketing_backend getUserTickets '(principal \"${OWNER}\")'"
echo ""