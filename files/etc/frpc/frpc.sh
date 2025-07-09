#!/bin/sh
# frpc monitor

SERVICE_NAME="frpc"
FRPC_DIR="/tmp/frpc"
FRPC_PATH="/tmp/frpc/frpc"
FRPC_CONFIG_PATH="/tmp/frpc/config.json"
FRPC_CONFIG_PATH_NEW="/tmp/frpc/config-new.json"

## Please fill in 
FRPC_URL=""
FRPC_CONFIG_URL=""

error_exit() {
    echo "$(date) Error: $1" >&2
    exit "${2:-1}"
}

mkdir -p $FRPC_DIR

# install frpc
if [ ! -f "$FRPC_PATH" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SERVICE_NAME} not found"
    rm -rf ${FRPC_DIR}/*
    wget --no-check-certificate -O $FRPC_PATH $FRPC_URL
    chmod +x $FRPC_PATH
fi

# not start
if ! pgrep -f "${SERVICE_NAME}" > /dev/null; then
    wget --no-check-certificate -O $FRPC_PATH $FRPC_URL
    mv $FRPC_CONFIG_PATH_NEW $FRPC_CONFIG_PATH
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SERVICE_NAME} to start" 
    /etc/init.d/${SERVICE_NAME} start
else
    current_hour=$(date +%H)
    if [ "$current_hour" -ge 1 ] && [ "$current_hour" -lt 2 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SERVICE_NAME} 1am and 2am, reload" 
        wget --no-check-certificate -O ${FRPC_CONFIG_PATH_NEW} $FRPC_CONFIG_URL
        mv $FRPC_CONFIG_PATH_NEW $FRPC_CONFIG_PATH
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ${SERVICE_NAME} reload" 
        /etc/init.d/${SERVICE_NAME} reload
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Skipping"
    fi
fi

