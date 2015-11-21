#!/bin/sh

[ "$DEBUG" == "" ] || DEBUG=

# Configure environment
[ "$TORAN_HOST" == "" ] && TORAN_HOST="example.org"
[ "$TORAN_PORT" == "" -a \( "$TORAN_SCHEME" == "" \) ] && TORAN_PORT=80 && TORAN_SCHEME="http"

[ "$TORAN_URL_HOST" == "" ] && TORAN_URL_HOST="$TORAN_HOST"
[ "$TORAN_URL_SCHEME" == "" ] && TORAN_URL_SCHEME="$TORAN_SCHEME"
[ "$TORAN_URL_PORT" == "" -a \( "$TORAN_URL_SCHEME" == "https" \) ] && TORAN_URL_PORT=443
[ "$TORAN_URL_PORT" == "" -a \( "$TORAN_URL_SCHEME" == "http" \) ] && TORAN_URL_PORT=80

if [ "$TORAN_URL" == "" ]; then
    TORAN_URL="//$TORAN_URL_HOST"
    [ "$TORAN_URL_SCHEME" != "" ] && TORAN_URL="$TORAN_URL_SCHEME:$TORAN_URL"
    [ "$TORAN_URL_SCHEME" == "http" -a \( "$TORAN_URL_PORT" != "80" \) ] && TORAN_URL="$TORAN_URL:$TORAN_URL_PORT"
    [ "$TORAN_URL_SCHEME" == "https" -a \( "$TORAN_URL_PORT" != "443" \) ] && TORAN_URL="$TORAN_URL:$TORAN_URL_PORT"
fi

export TORAN_URL
export TORAN_URL_PORT
export TORAN_URL_HOST

if [ "$DEBUG" != "" ]; then
    echo -en '\e[1;31m'
    echo "TORAN_HOST = $TORAN_HOST"
    echo "TORAN_SCHEME = $TORAN_SCHEME"
    echo "TORAN_PORT = $TORAN_PORT"
    echo "TORAN_URL_SCHEME = $TORAN_URL_SCHEME"
    echo "TORAN_URL_PORT = $TORAN_URL_PORT"
    echo "TORAN_URL_HOST = $TORAN_URL_HOST"
    echo "TORAN_URL = $TORAN_URL"
    echo -en '\e[0m'
fi

sed_escape()
{
    echo "$1" | sed -e 's/[]\/$*.^|[]/\\&/g'
}

# Replace ssh files
[ -f /data/keys/id_rsa ] && cat /data/keys/id_rsa > ~www-data/.ssh/id_rsa
[ -f /data/keys/id_rsa.pub ] && cat /data/keys/id_rsa.pub > ~www-data/.ssh/id_rsa.pub
[ -f /data/keys/known_hosts ] && cat /data/keys/known_hosts > ~www-data/.ssh/known_hosts
[ -f /data/keys/config ] && cat /data/keys/config > ~www-data/.ssh/config

# Patch configs
PARAMS_FILE="$TORAN_HOME/app/config/parameters.yml"
if [ "$TORAN_SCHEME" != "" ]; then
    [ "$TORAN_SCHEME" != "http" ] && sed -i 's/toran_scheme:.*$/toran_scheme: '"$TORAN_SCHEME"'/' "$PARAMS_FILE"
    [ "$TORAN_SCHEME" == "http" -a \( "$TORAN_PORT" != "80" \) ] && sed -i 's/toran_http_port:.*$/toran_http_port: '"$TORAN_PORT"'/' "$PARAMS_FILE"
    [ "$TORAN_SCHEME" == "https" -a \( "$TORAN_PORT" != "443" \) ] && sed -i 's/toran_https_port:.*$/toran_https_port: '"$TORAN_PORT"'/' "$PARAMS_FILE"
fi
[ "$TORAN_HOST" != "example.org" ] && sed -i 's/toran_host:.*$/toran_host: '"$TORAN_HOST"'/' "$PARAMS_FILE"

# Force cache flush
rm -rf "$TORAN_HOME/app/cache/prod"

echo -e "\n  ~/.ssh/config\n~~~~~~~~~~~~~~~~~~\e[1;30m"
cat ~www-data/.ssh/config
echo -e "\e[0m~~~~~~~~~~~~~~~~~~"

echo -e "\n  ~/.ssh/known_hosts\n~~~~~~~~~~~~~~~~~~\e[1;30m"
cat ~www-data/.ssh/known_hosts
echo -e "\e[0m~~~~~~~~~~~~~~~~~~"

echo -e "\n  ~/.ssh/id_rsa.pub\n~~~~~~~~~~~~~~~~~~\e[1;30m"
cat ~www-data/.ssh/id_rsa.pub
echo -e "\e[0m~~~~~~~~~~~~~~~~~~"

echo -e "\n  packages.json\n~~~~~~~~~~~~~~~~~~\e[1;30m"
cat $TORAN_HOME/web/repo/private/packages.json
echo -e "\e[0m~~~~~~~~~~~~~~~~~~"

echo -e "\n  parameters.yml\n~~~~~~~~~~~~~~~~~~\e[1;30m"
cat $TORAN_HOME/app/config/parameters.yml
echo -e "\e[0m~~~~~~~~~~~~~~~~~~"

/usr/bin/supervisord \
    --nodaemon \
    --pidfile /var/run/supervisord.pid \
    --configuration /etc/supervisord.conf
