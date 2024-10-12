#!/usr/local/bin/node

const express = require('express')
const crypto = require('crypto')

const app = express()
const port = 3000

const slat = "7edee98fe8cda35cf6576dcaa6a5a26f"

app.use(express.json());

function sha256(content) {
  return crypto.createHash('sha256').update(content).digest('hex')
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
    res.json({ result: "token-123456" })
    res.end();
})

app.post('/checkUserToken', function (req, res) {
    console.log(req.body)
    res.json({ result: "true" })
    res.end();
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})
