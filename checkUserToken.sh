#!/bin/bash

curl -X 'POST' \
  'http://127.0.0.1:3000/checkUserToken' \
  -H 'Content-Type: application/json' \
  -d '{
  "token": "bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b6d6bcf8e0c7d542f5e8e288aec067c448"
}'

echo ""
echo ""

curl -X 'POST' \
  'http://127.0.0.1:3000/checkUserToken' \
  -H 'Content-Type: application/json' \
  -d '{
  "token1": "bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b6d6bcf8e0c7d542f5e8e288aec067c448"
}'
