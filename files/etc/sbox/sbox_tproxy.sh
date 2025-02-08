#!/bin/sh
# sing-box monitor

SERVICE_NAME="sing-box"
SBOX_DIR="/tmp/sing-box"
SBOX_PATH="/tmp/sing-box/sing-box"
SBOX_CONFIG_PATH="/tmp/sing-box/config.json"
SBOX_CONFIG_PATH_NEW="/tmp/sing-box/config-new.json"

SBOX_URL="https://github.com/hotchilipowder/sing-box/releases/download/binary-linux_mipsle_softfloat/sing-box"
SBOX_CONFIG_URL=""

error_exit() {
    echo "$(date) Error: $1" >&2
    exit "${2:-1}"
}

mkdir -p $SBOX_DIR

if [ ! -f "$SBOX_PATH" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SERVICE_NAME} not found"

    sh /etc/sbox/sbox_tproxy_stop.sh
    rm -rf /tmp/sing-box/*
    wget --no-check-certificate -O $SBOX_PATH $SBOX_URL 
    chmod +x $SBOX_PATH
fi

# not start
if ! pgrep -f "${SERVICE_NAME}" > /dev/null; then
    wget --no-check-certificate -O ${SBOX_CONFIG_PATH_NEW} $SBOX_CONFIG_URL
    mv $SBOX_CONFIG_PATH_NEW $SBOX_CONFIG_PATH
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SERVICE_NAME} to start" 
    sh /etc/sbox/sbox_tproxy_stop.sh
    sh /etc/sbox/sbox_tproxy_start.sh
    /etc/init.d/${SERVICE_NAME} start
else
    current_hour=$(date +%H)
    if [ "$current_hour" -ge 1 ] && [ "$current_hour" -lt 2 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SERVICE_NAME} 1am and 2am, reload" 
        sh /etc/sbox/sbox_tproxy_stop.sh
        sh /etc/sbox/sbox_tproxy_start.sh
        wget --no-check-certificate -O ${SBOX_CONFIG_PATH_NEW} $SBOX_CONFIG_URL
        mv $SBOX_CONFIG_PATH_NEW $SBOX_CONFIG_PATH
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SERVICE_NAME} reload" 
        /etc/init.d/${SERVICE_NAME} reload
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipping"
    fi
fi
