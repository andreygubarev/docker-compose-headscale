#!/bin/sh

nohup socat TCP-LISTEN:8514,fork,reuseaddr TCP:headscale:8514 &
containerboot "$@"
