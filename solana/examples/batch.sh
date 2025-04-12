#!/bin/bash

PORT=4000

if command -v curl &> /dev/null
then
  echo "curl 已安装"
else
  echo "curl 未安装"
fi

if command -v jq &> /dev/null
then
  echo "jq 已安装"
else
  echo "jq 未安装"
fi

echo ""
echo ""


echo "1. GET /health"
curl -X 'GET' "http://127.0.0.1:$PORT/health" 2>/dev/null | jq .

echo ""
echo ""


echo "2. POST /getUserId"
curl -X 'POST' \
  "http://127.0.0.1:$PORT/getUserId" \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV"
}' 2>/dev/null | jq .

echo ""
echo ""


echo "3. POST /getUserToken"
curl -X 'POST' \
  "http://127.0.0.1:$PORT/getUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
  "uid": "c9fe7bf01a33e35c",
  "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"
}' 2>/dev/null | jq .

echo ""
echo ""

echo "4. POST /checkUserToken"
curl -X 'POST' \
  "http://127.0.0.1:$PORT/checkUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "token": "bec012cc4eeefe921fb5e944d851efa19a768638d1d6ec6620ed1a07f4067b026b773f616226fb3822618292597c27b69271f7e589ecfe50823b8ddbe6469eff"
}' 2>/dev/null | jq .

echo ""
