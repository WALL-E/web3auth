#!/bin/bash

curl -X 'POST' \
  'http://127.0.0.1:3000/checkUserToken' \
  -H 'Content-Type: application/json' \
  -d '{
  "token": "db19aea6cf7fe66624c49c28f7c3593f0891f3b5cc70aa6fb9ca82cb47676fab3da982a832687de181cd7c4c01c60c0b35738af8ca9a38598656028c985c635d"
}'
