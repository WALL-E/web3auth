#!/usr/bin/env node

import 'dotenv/config';
import { Connection, PublicKey, Transaction, TransactionInstruction } from '@solana/web3.js';
import TransportNodeHid from '@ledgerhq/hw-transport-node-hid';
import Solana from '@ledgerhq/hw-app-solana';
import bs58 from 'bs58';

// Configuration
const CLUSTER = process.env.CLUSTER || 'https://api.devnet.solana.com';
const API_BASE = process.env.API_BASE || 'http://127.0.0.1:4000';
const DEFAULT_DERIVATION_PATH = "44'/501'/0'/0'";

// Get derivation path from environment or use default
const derivationPath = process.env.DERIVATION_PATH || DEFAULT_DERIVATION_PATH;

console.log('🔗 Ledger Memo Token Test');
console.log(`Cluster: ${CLUSTER}`);
console.log(`API Base: ${API_BASE}`);
console.log(`Derivation Path: ${derivationPath}`);
console.log('');

async function connectLedger() {
  console.log('Connecting to Ledger device...');
  console.log('Ensure the Solana app is open on your Ledger.');
  
  const Transport = TransportNodeHid?.create ? TransportNodeHid : (TransportNodeHid?.default || TransportNodeHid);
  const transport = await Transport.create();
  const SolanaApp = Solana?.default || Solana;
  const solana = new SolanaApp(transport);
  
  return { transport, solana };
}

async function getLedgerAddress(solana, path) {
  console.log(`Getting address from path: ${path}`);
  const { address } = await solana.getAddress(path, true);
  
  // address may be a base58 string or a Buffer depending on interop
  let addressBase58;
  if (typeof address === 'string') {
    addressBase58 = address;
  } else {
    const buf = Buffer.isBuffer(address) ? address : Buffer.from(address);
    addressBase58 = bs58.encode(buf);
  }
  
  console.log(`Ledger address: ${addressBase58}`);
  return addressBase58;
}

async function callAPI(endpoint, method = 'GET', data = null) {
  const url = `${API_BASE}${endpoint}`;
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json'
    }
  };
  
  if (data) {
    options.body = JSON.stringify(data);
  }
  
  console.log(`📡 ${method} ${url}`);
  if (data) {
    console.log('Request data:', JSON.stringify(data, null, 2));
  }
  
  const response = await fetch(url, options);
  const result = await response.json();
  
  console.log(`Response status: ${response.status}`);
  console.log('Response data:', JSON.stringify(result, null, 2));
  
  if (!response.ok) {
    throw new Error(`API call failed: ${result.error || 'Unknown error'}`);
  }
  
  return result;
}

async function getUserId(address) {
  console.log('\n📋 Getting user ID...');
  const result = await callAPI('/getUserId', 'POST', { address });
  return result.result;
}

async function signMemoTransaction(solana, address, uid, path) {
  console.log('\n✍️ Creating and signing memo transaction...');
  
  const connection = new Connection(CLUSTER, 'confirmed');
  const publicKey = new PublicKey(address);
  
  // Get recent blockhash
  console.log('Getting recent blockhash...');
  const { blockhash } = await connection.getLatestBlockhash();
  console.log(`Recent blockhash: ${blockhash}`);
  
  // Create memo instruction
  const memoProgramId = new PublicKey('MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr');
  const memoData = Buffer.from(uid, 'utf8');
  const memoInstruction = new TransactionInstruction({
    programId: memoProgramId,
    keys: [],
    data: memoData
  });
  
  // Create transaction
  const transaction = new Transaction({
    feePayer: publicKey,
    recentBlockhash: blockhash
  });
  transaction.add(memoInstruction);
  
  // Set signers
  transaction.setSigners(publicKey);
  
  console.log(`Memo content: "${uid}"`);
  console.log('Transaction created, requesting signature from Ledger...');
  console.log('Please confirm the transaction on your Ledger...');
  
  // Sign with Ledger
  const message = transaction.serializeMessage();
  const signature = await solana.signTransaction(path, new Uint8Array(message));
  
  // Handle signature format
  let signatureBuffer;
  if (signature instanceof Buffer) {
    signatureBuffer = signature;
  } else if (signature.signature) {
    signatureBuffer = Buffer.from(signature.signature);
  } else {
    signatureBuffer = Buffer.from(signature);
  }
  
  console.log(`Signature received (${signatureBuffer.length} bytes)`);
  
  // Add signature to transaction
  transaction.addSignature(publicKey, signatureBuffer);
  
  // Serialize signed transaction
  const serialized = transaction.serialize({ requireAllSignatures: true });
  const base58Transaction = bs58.encode(serialized);
  
  console.log('Transaction signed successfully');
  console.log(`Serialized transaction length: ${base58Transaction.length} chars`);
  
  return base58Transaction;
}

async function getUserTokenByMemo(address, uid, transaction) {
  console.log('\n🎫 Getting user token by memo...');
  const result = await callAPI('/getUserTokenByMemo', 'POST', {
    address,
    uid,
    transaction
  });
  return result.result;
}

async function main() {
  let transport;
  
  try {
    // Connect to Ledger
    const { transport: ledgerTransport, solana } = await connectLedger();
    transport = ledgerTransport;
    
    // Get address
    const address = await getLedgerAddress(solana, derivationPath);
    
    // Get user ID
    const uid = await getUserId(address);
    console.log(`✅ User ID: ${uid}`);
    
    // Sign memo transaction
    const signedTransaction = await signMemoTransaction(solana, address, uid, derivationPath);
    
    // Get token
    const token = await getUserTokenByMemo(address, uid, signedTransaction);
    console.log(`✅ Token received: ${token}`);
    
    console.log('\n🎉 Test completed successfully!');
    console.log('\n📊 Summary:');
    console.log(`Address: ${address}`);
    console.log(`UID: ${uid}`);
    console.log(`Token: ${token}`);
    
  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
    if (error.stack) {
      console.error('Stack trace:', error.stack);
    }
    process.exit(1);
  } finally {
    if (transport) {
      await transport.close();
      console.log('\nLedger connection closed.');
    }
  }
}

// Handle process signals
process.on('SIGINT', async () => {
  console.log('\n\nReceived SIGINT, cleaning up...');
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n\nReceived SIGTERM, cleaning up...');
  process.exit(0);
});

main().catch(error => {
  console.error('Unhandled error:', error);
  process.exit(1);
});