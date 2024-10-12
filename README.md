# Web3Auth

Web3 User Authentication Service

## Supported wallets

- solana/phantom

# login step

1. /getUserId
   ```
   curl -X 'POST' \
    'http://127.0.0.1:3000/getUserId' \
    -H 'Content-Type: application/json' \
    -d '{
      "address": "5oNDL3swdJJF1g9DzJiZ4ynHXgszjAEpUkxVYejchzrY"
    }'

   {
     "result":"c9fe7bf01a33e35c"
   }
   ```
2. /getUserToken
   ```
   curl -X 'POST' \
    'http://127.0.0.1:3000/getUserToken' \
    -H 'Content-Type: application/json' \
    -d '{
      "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
      "uid": "c9fe7bf0",
      "signature": "52VJa6DBU92aMLkm5hVwJDNqQsjzKR3AZvqsX2EdAbtZVfMkzdLcS3oAdGbWP1c29wxYuPZkUNoNm6Eg9Mc7yGJD"
    }'

   {
     "result": "bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b6d6bcf8e0c7d542f5e8e288aec067c448"
   }
   ```
3. /checkUserToken
   ```
   curl -X 'POST' \
    'http://127.0.0.1:3000/checkUserToken' \
    -H 'Content-Type: application/json' \
    -d '{
      "token": "bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b6d6bcf8e0c7d542f5e8e288aec067c448"
    }'

   {
     "result":{
       "address":"7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
       "uid":"c9fe7bf0"
     }
   }
   ```
