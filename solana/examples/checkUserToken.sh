#!/bin/bash

PORT=4000

curl -X 'POST' \
  "http://127.0.0.1:$PORT/checkUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "token": "bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b69271f7e589ecfe50823b8ddbe6469eff"
}'

echo ""
echo ""

curl -X 'GET' \
  "http://127.0.0.1:$PORT/checkUserToken" \
  -H 'token: bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b69271f7e589ecfe50823b8ddbe6469eff'

echo ""
echo ""


curl -X 'POST' \
  "http://127.0.0.1:$PORT/checkUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "token1": "bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b69271f7e589ecfe50823b8ddbe6469eff"
}'

echo ""
echo ""

curl -X 'POST' \
  "http://127.0.0.1:$PORT/checkUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "token": "bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b69271f7e589ecfe50823b8ddbe6469eZZ"
}'

echo ""
echo ""
