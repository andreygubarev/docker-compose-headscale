#!/bin/sh

if [ -n "${TS_PORTFORWARD}" ]; then
    TS_LISTEN_PORT=${TS_PORTFORWARD%%:*}
    TS_REMOTE_ADDR=${TS_PORTFORWARD#*:}
    nohup socat "TCP-LISTEN:${TS_LISTEN_PORT},fork,reuseaddr" "TCP:${TS_REMOTE_ADDR}" &
fi

containerboot "$@"
