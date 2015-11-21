#!/bin/bash

generate_key()
{
    cd "$1"
    [ -f id_rsa ] && rm id_rsa
    [ -f id_rsa.pub ] && rm id_rsa.pub
    ssh-keygen -b 2048 -t rsa -f id_rsa -q -N '' -C "$2"
}

[ -d keys/ ] || mkdir -p keys/

COMMENT="$1"
[ -z "$COMMENT" ] && COMMENT="toran-proxy"

generate_key keys/ "$COMMENT"
