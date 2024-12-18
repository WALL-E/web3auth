#!/bin/bash

PORT=4000

curl -X 'POST' \
  "http://127.0.0.1:$PORT/getUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
  "uid": "c9fe7bf01a33e35c",
  "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"
}'

echo ""
echo ""

curl -X 'POST' \
  "http://127.0.0.1:$PORT/getUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqZZ",
  "uid": "c9fe7bf01a33e35c",
  "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"
}'

echo ""
echo ""


curl -X 'POST' \
  "http://127.0.0.1:$PORT/getUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
  "uid": "c9fe7bf01a33e35cXX",
  "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"
}'


echo ""
echo ""

curl -X 'POST' \
  "http://127.0.0.1:$PORT/getUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
  "uid": "c9fe7bf01a33e35c",
  "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VZZ"
}'

echo ""
echo ""

curl -X 'POST' \
  "http://127.0.0.1:$PORT/getUserToken" \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "7iCzEsN1xrV9gZoWMvUaWKhAhy1Cqm9iAeVAmJVThCqV",
  "uid2": "c9fe7bf01a33e35c",
  "signature": "397KqXkGyYkxxdBNUqDY1fpvVv7ccXFeJoDmieeawN2KPGmNbthvTPMDDcEM1NDnGTftcMf7EFnTSUoDG2Pg8VY5"
}'

echo ""
echo ""


