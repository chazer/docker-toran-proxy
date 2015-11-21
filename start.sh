#!/bin/bash

IMAGE="local/toran"
CID="toran"

docker_stop() { docker ps -qf name="$1" | xargs -r -t docker stop; }
docker_remove() { docker ps -aqf name="$1" | xargs -r -t docker rm; }

docker_stop $CID
docker_remove $CID
docker build -t $IMAGE .

docker run -d \
    --name $CID \
    -P \
    -v "/`pwd`/keys:/data/keys" \
    -e "TORAN_HOST=composer.local" \
    $IMAGE || exit 1

docker logs $CID

DOCKER_IP=$(echo ${DOCKER_HOST:6}|cut -d':' -f 1)
DOCKER_PORT=$(docker port $CID 80/tcp|cut -d':' -f 2)
[[ "$DOCKER_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] || DOCKER_IP="127.0.0.1"

if [ "$DOCKER_PORT" == "" ]; then
    echo -e '\e[1;31m'
    echo -e "\t Something wrong, check \e[0;36mdocker ps\e[1;31m command"
    echo -e '\e[0m'
    exit 1
fi

echo -e '\e[1;31m'
echo -e "\t Next, open \e[0;36mhttp://$DOCKER_IP:$DOCKER_PORT/setup\e[1;31m in your Web browser."
echo -e '\e[0m'
