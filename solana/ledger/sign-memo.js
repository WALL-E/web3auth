#!/usr/bin/env node

// Sign a Memo transaction using Ledger Solana app
// Usage:
//   node ledger/sign-memo.js "Hello from Ledger"

import 'dotenv/config';
import TransportNodeHid from '@ledgerhq/hw-transport-node-hid';
import Solana from '@ledgerhq/hw-app-solana';
import { Connection, PublicKey, Transaction, TransactionInstruction } from '@solana/web3.js';
import bs58 from 'bs58';

const DEFAULT_DERIVATION_PATH = "44'/501'/0/0'"; // User-specified default path
const MEMO_PROGRAM_ID = new PublicKey('MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr');

// Validate signatures and extract memo string from a transaction
// Only accepts base58-encoded serialized transaction string
function validateAndExtractMemo(input) {
  try {
    if (typeof input !== 'string') {
      return { isValid: false, memo: null };
    }
    const buf = bs58.decode(input);
    const tx = Transaction.from(buf);

    const isValid = tx.verifySignatures();
    let memo = null;
    // Extract signer addresses from compiled message header
    const msg = tx.compileMessage();
    const signers = msg.accountKeys
      .slice(0, msg.header.numRequiredSignatures)
      .map(k => k.toBase58());

    // Prefer explicit instructions if present
    if (Array.isArray(tx.instructions) && tx.instructions.length > 0) {
      for (const ix of tx.instructions) {
        if (ix.programId && ix.programId.equals(MEMO_PROGRAM_ID)) {
          memo = ix.data ? ix.data.toString('utf8') : '';
          break;
        }
      }
    }

    // Fallback: reconstruct from compiled message if needed
    if (memo == null) {
      const msg = tx.compileMessage();
      for (const ci of msg.instructions) {
        const programId = msg.accountKeys[ci.programIdIndex];
        if (programId.equals(MEMO_PROGRAM_ID)) {
          memo = Buffer.from(ci.data).toString('utf8');
          break;
        }
      }
    }

    return { isValid, memo, signers };
  } catch (e) {
    return { isValid: false, memo: null, signers: [] };
  }
}

async function main() {
  try {
    const memo = process.argv[2];
    if (!memo || memo.length === 0) {
      console.error('Usage: node ledger/sign-memo.js "your memo string"');
      process.exit(1);
    }

    // RPC connection to fetch latest blockhash
    const cluster = process.env.CLUSTER || process.env.SOLANA_RPC || 'https://api.devnet.solana.com';
    const connection = new Connection(cluster, 'confirmed');

    console.log('Connecting to Ledger device...');
    // Handle ESM/CommonJS default export interop
    const Transport = TransportNodeHid?.create ? TransportNodeHid : (TransportNodeHid?.default || TransportNodeHid);
    const transport = await Transport.create();
    const SolanaApp = Solana?.default || Solana;
    const solana = new SolanaApp(transport);

    console.log('Ensure the Solana app is open on your Ledger.');
    const path = process.env.LEDGER_PATH || process.argv[3] || DEFAULT_DERIVATION_PATH;
    const { address } = await solana.getAddress(path, true);
    // address may be a base58 string or a Buffer depending on interop
    let addressBase58;
    let feePayer;
    if (typeof address === 'string') {
      addressBase58 = address;
      feePayer = new PublicKey(addressBase58);
    } else {
      const buf = Buffer.isBuffer(address) ? address : Buffer.from(address);
      addressBase58 = bs58.encode(buf);
      feePayer = new PublicKey(buf);
    }
    console.log(`Ledger address (fee payer): ${addressBase58}`);

    // Fetch recent blockhash from RPC
    const { blockhash } = await connection.getLatestBlockhash('finalized');


    // Build memo instruction with no additional keys (fee payer implicit)
    const memoIx = new TransactionInstruction({
      keys: [],
      programId: MEMO_PROGRAM_ID,
      data: Buffer.from(memo, 'utf8')
    });

    // Assemble transaction
    const tx = new Transaction();
    tx.add(memoIx);
    tx.feePayer = feePayer;
    // Ensure the fee payer is marked as a required signer
    tx.setSigners(feePayer);
    tx.recentBlockhash = blockhash;

    // Debug: show compiled message accounts and header
    const compiled = tx.compileMessage();
    console.log(`Accounts in message: ${compiled.accountKeys.map(k => k.toBase58()).join(', ')}`);
    console.log(`Header: reqSig=${compiled.header.numRequiredSignatures}, roSig=${compiled.header.numReadonlySignedAccounts}, roUnsig=${compiled.header.numReadonlyUnsignedAccounts}`);

    // Serialize message for signing (includes required signers)
    const message = tx.serializeMessage();
    const messageBytes = new Uint8Array(message);
    // Also prepare wire format unsigned transaction for fallback signing
    const wireUnsigned = tx.serialize({ requireAllSignatures: false, verifySignatures: false });

    console.log('Please confirm the transaction on your Ledger...');
    let signature;
    try {
      signature = await solana.signTransaction(path, messageBytes);
    } catch (e) {
      console.warn('Message signing failed, trying wire transaction base64...');
      const wireBase64 = Buffer.from(wireUnsigned).toString('base64');
      // Some versions of hw-app-solana expect base64 string for the tx
      signature = await solana.signTransaction(path, wireBase64);
    }
    // Normalize signature to Buffer
    if (signature && signature.signature) {
      signature = signature.signature;
    }
    if (!(signature instanceof Buffer)) {
      signature = Buffer.isBuffer(signature) ? signature : Buffer.from(signature);
    }

    // Attach signature
    tx.addSignature(feePayer, signature);

    const isValid = tx.verifySignatures();
    if (!isValid) {
      throw new Error('Signature verification failed');
    }

    const sigBase58 = bs58.encode(signature);
    const txSerialized = tx.serialize();
    const txBase58 = bs58.encode(txSerialized);

    // Validate and extract memo, print as JSON
    const check = validateAndExtractMemo(txBase58);
    const resultJson = {
      signatureValid: check.isValid,
      memo: check.memo ?? '',
      signers: check.signers || []
    };
    console.log(JSON.stringify(resultJson, null, 2));

    console.log('--- Signed Memo Transaction ---');
    console.log(`Cluster: ${cluster}`);
    console.log(`Fee Payer: ${addressBase58}`);
    console.log(`Memo: ${memo}`);
    console.log(`Transaction (base58): ${txBase58}`);

    // Offline only: no broadcast

    await transport.close();
    console.log('Done.');
  } catch (err) {
    console.error('Error:', err.message || err);
    process.exit(1);
  }
}

main();