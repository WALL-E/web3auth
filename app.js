#!/usr/local/bin/node

//
// Ref: https://nodejs.org/api/crypto.html
//

require('dotenv').config();
const express = require('express')
const crypto = require('crypto')

const web3 = require("@solana/web3.js");
const tweetnacl = require("tweetnacl");
const bs58 = require("bs58");

const app = express()
const port = process.env.PORT || 3000;

const SLAT = process.env.SALT;
const KEY = process.env.KEY;
const IV = process.env.IV;

app.use(express.json());

function sha256(content) {
  return crypto.createHash('sha256').update(content).digest('hex')
}

function aesEncrypt(plaintext) {
    const cipher = crypto.createCipheriv('aes-256-cbc', KEY, IV);
    var crypted = cipher.update(plaintext, 'utf8', 'hex');
    crypted += cipher.final('hex');

    return crypted;
}

function aesDecrypt(ciphertext) {
    const decipher = crypto.createDecipheriv('aes-256-cbc', KEY, IV);
    var decrypted = decipher.update(ciphertext, 'hex', 'utf8');
    decrypted += decipher.final('utf8');

    return decrypted;
}

app.get('/', (req, res) => {
    res.json({ message: "Web3 User Authentication Service" })
    return res.end();
})

app.get('/health', (req, res) => {
    res.json({ message: "ok" })
    return res.end();
})

app.post('/getUserId', function (req, res) {
    const address = req.body.address;
    if (!address) {
        res.status(400).json({ error: "parms {address} must be set" })
    } else {
        const hash = sha256(address + SLAT)
        //
        // Maximum number of users supported,
        // The probability of collision is extremely small
        //
        // C(36,16) = 7,307,872,110
        //
        const uid = hash.substring(0, 16)
        res.json({ result: uid })
    }

    return res.end();
})

app.post('/getUserToken', function (req, res) {
    const address = req.body.address;
    const signature = req.body.signature;
    const uid = req.body.uid;
    if (!address || !signature || !uid) {
        res.status(400).json({ error: "parms {address, signature, uid} must be set" })
        return res.end();
    }
    //
    // verify signature
    //
    try {
        const publicKey = new web3.PublicKey(address);
        const messageBytes = new TextEncoder().encode(uid)
        const result = tweetnacl.sign.detached.verify(
            messageBytes,
            bs58.decode(signature),
            publicKey.toBytes(),
        );
        if(!result) {
            res.status(400).json({ error: "signature not valid!" });
            return res.end();
        }
    } catch (error) {
        console.error('Error in getUserToken[1]:', error.message);
        res.status(500).json({ error: "Internal server error" });
        return res.end();
    }

    //
    // generate token
    //
    const plaintext = address + "," + uid
    try {
        const ciphertext = aesEncrypt(plaintext);
        res.json({ result: ciphertext })
        return res.end();
    } catch (error) {
        console.error('Error in getUserToken[2]:', error.message);
        res.status(500).json({ error: "Internal server error" });
        return res.end();
    }
})

app.post('/checkUserToken', function (req, res) {
    const ciphertext = req.body.token;
    if (!ciphertext) {
        res.status(400).json({ error: "parms {token} must be set" })
        return res.end();
    }

    try {
        const plaintext = aesDecrypt(ciphertext);
        const tmp = plaintext.split(",")

        res.json({
            result: {
                address: tmp[0],
                uid: tmp[1]
            }
        })
        return res.end();
    } catch (error) {
        console.error('Error in checkUserToken:', error.message);
        res.status(500).json({ error: "Internal server error" });
        return res.end();
    }
})

app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send({ error: "something broke!" });
});

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
