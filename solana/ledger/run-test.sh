#!/bin/bash

# Ledger Memo Token Test Runner
echo "🔗 Ledger Memo Token Test Runner"
echo "================================"

# Check if server is running
echo "Checking if server is running..."
if ! curl -s http://127.0.0.1:4000/health > /dev/null; then
    echo "❌ Server is not running. Please start the server first:"
    echo "   cd /Users/zhangzheng/web3auth/solana"
    echo "   node app.js"
    exit 1
fi

echo "✅ Server is running"
echo ""

# Run the test
echo "Starting Ledger test..."
echo "Make sure:"
echo "1. Your Ledger device is connected"
echo "2. The Solana app is open on your Ledger"
echo "3. Blind signing is enabled (if required)"
echo ""

cd "$(dirname "$0")"
node test-memo-token.js