#!/bin/sh

> keys/known_hosts

./keygen.sh "toran-proxy@docker.local"

./addkey.sh github.com
./addkey.sh bitbucket.com
