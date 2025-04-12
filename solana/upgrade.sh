#!/bin/bash

#!/bin/bash
#

APP=web3auth

docker rm -f $APP
docker rmi -f $APP:latest

docker build -t $APP .
docker run -itd \
        --restart always \
        --network host \
        --name $APP \
        $APP:latest
