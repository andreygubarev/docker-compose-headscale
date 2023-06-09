#!/bin/bash
set -eux

export DEBIAN_FRONTEND=noninteractive

tor_monitor() {
  TOR_MONITOR=0
  TOR_MONITOR_THRESHOLD=30
  while [ $TOR_MONITOR -lt $TOR_MONITOR_THRESHOLD ]; do
    sleep 1
    TOR_MONITOR=$((TOR_MONITOR+1))
    if [ ! -f /etc/tor/run/control.authcookie ]; then
      continue
    fi
    TOR_AUTHCOOKIE="$(xxd -p -c 32 /etc/tor/run/control.authcookie)"
    TOR_CONTROL=$(printf "AUTHENTICATE %s\r\nGETINFO status/bootstrap-phase\r\nQUIT\r\n" "$TOR_AUTHCOOKIE")
    TOR_STATUS="$(echo "$TOR_CONTROL" | nc 127.0.0.1 9051 | grep 'bootstrap-phase')"
    if echo "$TOR_STATUS" | grep -q "TAG=done"; then
      return 0
    fi
  done
  return 1
}

if tor_monitor; then
  echo "Tor status: connected"
else
  echo "Tor status: failed to connect after $TOR_MONITOR_THRESHOLD seconds"
  exit 1
fi

curl -fsSL http://headscale:8514/health
