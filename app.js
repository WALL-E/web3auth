#!/usr/local/bin/node
//
//
// Ref: https://juejin.cn/post/6844903969395834887
//
//

const express = require('express')
const crypto = require('crypto')

const app = express()
const port = 3000

const slat = "7edee98fe8cda35cf6576dcaa6a5a26f"
const key = 'Password!';

app.use(express.json());

function sha256(content) {
  return crypto.createHash('sha256').update(content).digest('hex')
}

function aesEncrypt(data, key) {
  const cipher = crypto.createCipher('aes192', key);
  var crypted = cipher.update(data, 'utf8', 'hex');
  crypted += cipher.final('hex');
  return crypted;
}

function aesDecrypt(encrypted, key) {
  const decipher = crypto.createDecipher('aes192', key);
  var decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

app.get('/', (req, res) => {
  res.send('Hello Builder!')
})

app.post('/getUserId', function (req, res) {
    console.log(req.body)
    const address = req.body.address;
    const hash = sha256(address + slat)
    const uid = hash.substring(0, 8)
    res.json({ result: uid })
    res.end();
})

app.post('/getUserToken', function (req, res) {
    console.log(req.body)
    const address = req.body.address;
    const signature = req.body.signature;
    const uid = req.body.uid;
    //
    // TODO: verify signature
    //

    const data = address + "," + uid
    const encrypted = aesEncrypt(data, key);


    res.json({ result: encrypted })
    res.end();
})

app.post('/checkUserToken', function (req, res) {
    console.log(req.body)
    const encrypted = req.body.token;

    const decrypted = aesDecrypt(encrypted, key);
    console.log(decrypted)
    const tmp = decrypted.split(",")

    res.json({
        result: {
            address: tmp[0],
            uid: tmp[1]
        }
    })
    res.end();
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
