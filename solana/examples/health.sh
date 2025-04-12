#!/bin/bash

echo "GET /"
curl -X 'GET' 'http://127.0.0.1:3000/'

echo ""
echo ""

echo "GET /health"
curl -X 'GET' 'http://127.0.0.1:3000/health'

echo ""
