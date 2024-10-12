#!/bin/bash

curl -X 'POST' \
  'http://127.0.0.1:3000/checkUserToken' \
  -H 'Content-Type: application/json' \
  -d '{
  "token": "bb80e74d0ff90444f7d0caf2807ad8ef930ec096405d8f12b4f0c2e3bac59c59599bf0e109d41deef39b1d25cab3d55ff38c99f69acb823d7e55b7b2dfda6a29"
}'
