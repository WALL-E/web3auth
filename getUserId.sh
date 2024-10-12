#!/bin/bash

curl -X 'POST' \
  'http://127.0.0.1:3000/getUserId' \
  -H 'Content-Type: application/json' \
  -d '{
  "address": "5DkgLGarMN3BNXkGzKUNVW5t2wDCThAhGR22e1deeViy"
}'
