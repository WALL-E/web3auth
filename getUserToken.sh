#!/bin/bash

curl -X 'POST' \
  'http://127.0.0.1:3000/getUserToken' \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
  "uid": "c9fe7bf0",
  "signature": "52VJa6DBU92aMLkm5hVwJDNqQsjzKR3AZvqsX2EdAbtZVfMkzdLcS3oAdGbWP1c29wxYuPZkUNoNm6Eg9Mc7yGJD"
}'

echo ""
echo ""

curl -X 'POST' \
  'http://127.0.0.1:3000/getUserToken' \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
  "uid": "c9fe7bf0",
  "signature": "52VJa6DBU92aMLkm5hVwJDNqQsjzKR3AZvqsX2EdAbtZVfMkzdLcS3oAdGbWP1c29wxYuPZkUNoNm6Eg9Mc7yGXX"
}'


echo ""
echo ""

curl -X 'POST' \
  'http://127.0.0.1:3000/getUserToken' \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
  "uid2": "c9fe7bf0",
  "signature": "52VJa6DBU92aMLkm5hVwJDNqQsjzKR3AZvqsX2EdAbtZVfMkzdLcS3oAdGbWP1c29wxYuPZkUNoNm6Eg9Mc7yGXX"
}'


