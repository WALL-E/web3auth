#!/usr/bin/env node

import 'dotenv/config';
import express from 'express';
import crypto from 'crypto';
import helmet from 'helmet';
import cors from 'cors';
import { Connection, PublicKey, Transaction } from '@solana/web3.js';
import nacl from 'tweetnacl';
import bs58 from 'bs58';

// Environment variables validation
const requiredEnvVars = ['SALT', 'KEY', 'IV', 'CLUSTER'];
const missingVars = requiredEnvVars.filter(varName => !process.env[varName]);
if (missingVars.length > 0) {
  console.error(`Missing required environment variables: ${missingVars.join(', ')}`);
  process.exit(1);
}

const app = express();
const port = process.env.PORT || 4000;

// Environment variables
const SALT = process.env.SALT;
const KEY = Buffer.from(process.env.KEY, 'hex');
const IV = Buffer.from(process.env.IV, 'hex');
const MIN_BALANCE = parseInt(process.env.MIN_BALANCE) || 0;
const CLUSTER = process.env.CLUSTER;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));

// Body parser with error handling
app.use(express.json({ 
  limit: '10mb',
  verify: (req, res, buf, encoding) => {
    // Store raw body for potential error handling
    req.rawBody = buf;
  }
}));

// JSON parsing error handler
app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    console.error('JSON parsing error:', err.message);
    return res.status(400).json({ 
      error: 'Invalid JSON format',
      details: 'Request body contains malformed JSON'
    });
  }
  next(err);
});

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`${new Date().toISOString()} ${req.method} ${req.path} ${res.statusCode} ${duration}ms`);
  });
  next();
});

// Utility functions
function sha256(content) {
  return crypto.createHash('sha256').update(content).digest('hex');
}

function findUserId(address) {
  const hash = sha256(address + SALT);
  // Maximum number of users supported: C(36,16) = 7,307,872,110
  // The probability of collision is extremely small
  return hash.substring(0, 16);
}

function validateAddress(address) {
  try {
    if (!address || typeof address !== 'string') {
      return { isValid: false, error: 'Address must be a non-empty string' };
    }

    const publicKey = new PublicKey(address);
    const decoded = bs58.decode(address);

    if (decoded.length !== 32) {
      return { isValid: false, error: 'Invalid address length after decoding' };
    }

    if (!PublicKey.isOnCurve(decoded)) {
      return { isValid: false, error: 'Address is not on ed25519 curve' };
    }

    return { isValid: true, publicKey: publicKey.toBase58() };
  } catch (error) {
    return { isValid: false, error: error.message };
  }
}

function aesEncrypt(plaintext) {
  try {
    const cipher = crypto.createCipheriv('aes-256-cbc', KEY, IV);
    let encrypted = cipher.update(plaintext, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    return encrypted;
  } catch (error) {
    throw new Error('Encryption failed: ' + error.message);
  }
}

function aesDecrypt(ciphertext) {
  try {
    const decipher = crypto.createDecipheriv('aes-256-cbc', KEY, IV);
    let decrypted = decipher.update(ciphertext, 'hex', 'utf8');
    decrypted += decipher.final('utf8');
    return decrypted;
  } catch (error) {
    throw new Error('Decryption failed: ' + error.message);
  }
}

async function getBalance(address) {
  try {
    const connection = new Connection(CLUSTER, 'confirmed');
    const wallet = new PublicKey(address);
    const balance = await connection.getBalance(wallet);
    return balance;
  } catch (error) {
    throw new Error('Failed to get balance: ' + error.message);
  }
}

// Input validation middleware
function validateRequiredFields(fields) {
  return (req, res, next) => {
    const missing = fields.filter(field => !req.body[field]);
    if (missing.length > 0) {
      return res.status(400).json({
        error: 'Missing required fields',
        missing: missing
      });
    }
    next();
  };
}

// Error response helper
function sendError(res, status, message, details = null) {
  const response = { error: message };
  if (details) response.details = details;
  return res.status(status).json(response);
}

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Web3 User Authentication Service',
    version: '1.0.0',
    endpoints: ['/health', '/getUserId', '/getUserToken', '/getUserTokenByMemo', '/checkUserToken']
  });
});

app.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'ok',
    uptime: process.uptime(),
    bin_name: 'web3auth'
  });
});

app.post('/getUserId', validateRequiredFields(['address']), (req, res) => {
  try {
    const { address } = req.body;
    
    const validation = validateAddress(address);
    if (!validation.isValid) {
      return sendError(res, 400, 'Invalid address', validation.error);
    }

    const uid = findUserId(address);
    res.json({ result: uid });
  } catch (error) {
    console.error('Error in getUserId:', error.message);
    sendError(res, 500, 'Internal server error');
  }
});

app.post('/getUserToken', validateRequiredFields(['address', 'signature', 'uid']), async (req, res) => {
  try {
    const { address, signature, uid } = req.body;
    
    // Check for extra fields
    const allowedFields = ['address', 'signature', 'uid'];
    const requestFields = Object.keys(req.body);
    const extraFields = requestFields.filter(field => !allowedFields.includes(field));
    
    if (extraFields.length > 0) {
      return sendError(res, 400, 'Extra fields not allowed', `Unexpected fields: ${extraFields.join(', ')}`);
    }

    // Verify balance if minimum balance is set
    if (MIN_BALANCE > 0) {
      const balance = await getBalance(address);
      console.log('Account balance (LAMPORTS):', balance);
      if (balance < MIN_BALANCE) {
        return sendError(res, 403, `Account balance must be greater than ${MIN_BALANCE} LAMPORTS`);
      }
    }

    // Verify address
    const validation = validateAddress(address);
    if (!validation.isValid) {
      return sendError(res, 400, 'Invalid address', validation.error);
    }

    // Verify uid
    const expectedUid = findUserId(address);
    if (uid !== expectedUid) {
      return sendError(res, 400, 'Invalid uid');
    }

    // Verify signature
    try {
      const publicKey = new PublicKey(address);
      const messageBytes = new TextEncoder().encode(uid);
      const signatureBytes = bs58.decode(signature);
      
      // Check signature size
      if (signatureBytes.length !== 64) {
        return sendError(res, 400, 'Invalid signature', 'Signature must be 64 bytes');
      }
      
      const isValidSignature = nacl.sign.detached.verify(
        messageBytes,
        signatureBytes,
        publicKey.toBytes()
      );

      if (!isValidSignature) {
        return sendError(res, 400, 'Invalid signature');
      }
    } catch (error) {
      console.error('Signature verification error:', error.message);
      return sendError(res, 400, 'Invalid signature', error.message);
    }

    // Generate token
    try {
      const plaintext = `${address},${uid}`;
      const token = aesEncrypt(plaintext);
      res.json({ result: token });
    } catch (error) {
      console.error('Token generation error:', error.message);
      return sendError(res, 500, 'Token generation failed');
    }
  } catch (error) {
    console.error('Error in getUserToken:', error.message);
    sendError(res, 500, 'Internal server error');
  }
});

// Verify a base58-encoded serialized transaction contains a valid signature from address
function verifyTransactionSignatureByAddress(transactionBase58, address, uid) {
  try {
    const txBytes = bs58.decode(transactionBase58);
    const tx = Transaction.from(txBytes);

    // Extract signers from compiled message
    const message = tx.compileMessage();
    const signerKeys = message.accountKeys
      .slice(0, message.header.numRequiredSignatures);
    const signerBase58s = signerKeys.map(k => k.toBase58());

    // Ensure the address is among required signers
    if (!signerBase58s.includes(address)) {
      return { ok: false, reason: 'Address is not among required signers', signers: signerBase58s };
    }

    // Find signature corresponding to the address
    const targetPubkey = new PublicKey(address);
    const sigEntry = tx.signatures.find(s => s.publicKey.equals(targetPubkey));
    if (!sigEntry || !sigEntry.signature) {
      return { ok: false, reason: 'Signature for address not found', signers: signerBase58s };
    }

    // Verify signature against the message bytes
    const msgBytes = tx.serializeMessage();
    const isValid = nacl.sign.detached.verify(
      new Uint8Array(msgBytes),
      new Uint8Array(sigEntry.signature),
      targetPubkey.toBytes()
    );

    if (!isValid) {
      return { ok: false, reason: 'Invalid signature for address', signers: signerBase58s };
    }

    // Validate memo content equals provided uid (Memo must be present)
    const MEMO_PROGRAM_ID = 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr';
    const memoIx = tx.instructions?.find(ix => ix.programId?.toBase58() === MEMO_PROGRAM_ID);
    const memoText = memoIx && memoIx.data ? Buffer.from(memoIx.data).toString('utf8') : null;
    if (!memoText) {
      return { ok: false, reason: 'Memo instruction not found or empty', signers: signerBase58s, memo: null };
    }
    if (memoText !== uid) {
      return { ok: false, reason: 'Memo does not match uid', signers: signerBase58s, memo: memoText };
    }

    return { ok: true, signers: signerBase58s, memo: memoText };
  } catch (error) {
    return { ok: false, reason: error.message, signers: [], memo: null };
  }
}

// Get user token by verifying signature inside a serialized transaction (e.g., memo transaction)
app.post('/getUserTokenByMemo', validateRequiredFields(['address', 'uid', 'transaction']), async (req, res) => {
  try {
    const { address, uid, transaction } = req.body;

    // Check for extra fields
    const allowedFields = ['address', 'uid', 'transaction'];
    const requestFields = Object.keys(req.body);
    const extraFields = requestFields.filter(field => !allowedFields.includes(field));
    if (extraFields.length > 0) {
      return sendError(res, 400, 'Extra fields not allowed', `Unexpected fields: ${extraFields.join(', ')}`);
    }

    // Verify address
    const validation = validateAddress(address);
    if (!validation.isValid) {
      return sendError(res, 400, 'Invalid address', validation.error);
    }

    // Verify uid matches address-derived id
    const expectedUid = findUserId(address);
    if (uid !== expectedUid) {
      return sendError(res, 400, 'Invalid uid');
    }

    // Optional: verify balance if minimum balance is set (consistent with getUserToken)
    if (MIN_BALANCE > 0) {
      const balance = await getBalance(address);
      console.log('Account balance (LAMPORTS):', balance);
      if (balance < MIN_BALANCE) {
        return sendError(res, 403, `Account balance must be greater than ${MIN_BALANCE} LAMPORTS`);
      }
    }

    // Verify transaction contains a valid signature from the address
    const check = verifyTransactionSignatureByAddress(transaction, address, uid);
    if (!check.ok) {
      return sendError(res, 400, 'Signature verification failed', check.reason);
    }

    // Generate token (same rule as getUserToken)
    try {
      const plaintext = `${address},${uid}`;
      const token = aesEncrypt(plaintext);
      res.json({ result: token });
    } catch (error) {
      console.error('Token generation error:', error.message);
      return sendError(res, 500, 'Token generation failed');
    }
  } catch (error) {
    console.error('Error in getUserTokenByMemo:', error.message);
    sendError(res, 500, 'Internal server error');
  }
});

// Unified checkUserToken handler
function handleCheckUserToken(req, res) {
  try {
    // Get token from body (POST) or header (GET)
    const token = req.body?.token || req.get('token');
    
    if (!token) {
      const source = req.method === 'POST' ? 'body' : 'header';
      return sendError(res, 400, `Token must be provided in ${source}`);
    }

    const plaintext = aesDecrypt(token);
    const parts = plaintext.split(',');
    
    if (parts.length !== 2) {
      return sendError(res, 400, 'Invalid token format');
    }

    const [address, uid] = parts;
    
    // Validate the extracted data
    const validation = validateAddress(address);
    if (!validation.isValid) {
      return sendError(res, 400, 'Invalid address in token');
    }

    const expectedUid = findUserId(address);
    if (uid !== expectedUid) {
      return sendError(res, 400, 'Invalid uid in token');
    }

    res.json({
      result: { address, uid }
    });
  } catch (error) {
    console.error('Error in checkUserToken:', error.message);
    sendError(res, 400, 'Invalid or expired token');
  }
}

app.post('/checkUserToken', handleCheckUserToken);
app.get('/checkUserToken', handleCheckUserToken);

// Global error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err.stack);
  sendError(res, 500, 'An unexpected error occurred');
});

// 404 handler
app.use('*', (req, res) => {
  sendError(res, 404, 'Endpoint not found');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  process.exit(0);
});

app.listen(port, () => {
  console.log(`Web3auth app listening on port ${port}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Cluster: ${CLUSTER}`);
  console.log(`Min balance: ${MIN_BALANCE} LAMPORTS`);
});
