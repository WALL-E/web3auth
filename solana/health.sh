#!/bin/bash

curl -X 'GET' 'http://127.0.0.1:3000/'

echo ""

curl -X 'GET' 'http://127.0.0.1:3000/health'
