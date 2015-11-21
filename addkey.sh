#!/bin/sh

HOST=$(echo "$1:"|cut -d':' -f 1)
PORT=$(echo "$1:"|cut -d':' -f 2)

[ -z "$PORT" ] && PORT=22

ssh-keyscan -p "$PORT" "$HOST" >> keys/known_hosts
