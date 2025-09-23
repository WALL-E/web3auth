#!/bin/bash

APP=web3auth

docker rm -f $APP
docker rmi -f $APP:latest

docker build -t $APP .
docker run -itd \
        --restart always \
        -p 4000:4000 \
        --name $APP \
        $APP:latest
