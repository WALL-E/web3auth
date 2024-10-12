const express = require('express')
const app = express()
const port = 3000

app.use(express.json());

app.get('/', (req, res) => {
  res.send('Hello World!')
})

app.post('/getUserId', function (req, res) {
    console.log(req.body)
    res.json({ result: "uid-123456" })
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
