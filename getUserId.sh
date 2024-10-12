#!/bin/bash

curl -X 'POST' \
  'http://127.0.0.1:3000/getUserId' \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV"
}'

echo ""
echo ""

curl -X 'POST' \
  'http://127.0.0.1:3000/getUserId' \
  -H 'Content-Type: application/json' \
  -d '{
  "address2": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV"
}'
