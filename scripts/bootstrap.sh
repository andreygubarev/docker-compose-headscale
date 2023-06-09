#!/bin/sh
set -eux

export DEBIAN_FRONTEND=noninteractive
apt-get update

### Install Tor ##############################################################

apt-get install -yq --no-install-recommends \
    tor obfs4proxy netcat
systemctl enable --now tor.service

cat << 'EOF' > /etc/tor/torrc
ControlPort 127.0.0.1:9051
CookieAuthentication 1

SocksPort 127.0.0.1:9050
Log notice syslog

CircuitBuildTimeout 60
KeepalivePeriod 60
NewCircuitPeriod 30
NumEntryGuards 8

UseBridges 0
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy
EOF
systemctl restart tor.service

tor_monitor() {
  TOR_MONITOR=0
  TOR_MONITOR_THRESHOLD=30
  while [ $TOR_MONITOR -lt $TOR_MONITOR_THRESHOLD ]; do
    sleep 1
    TOR_MONITOR=$((TOR_MONITOR+1))
    if [ ! -f /var/run/tor/control.authcookie ]; then
      continue
    fi
    TOR_AUTHCOOKIE="$(xxd -p -c 32 /var/run/tor/control.authcookie)"
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

### Install Socat ############################################################

apt-get install -yq --no-install-recommends \
    socat

cat << 'EOF' > /etc/systemd/system/socat.service
[Unit]
Description=Socat Service
After=network.target

[Service]
Environment=SOCAT_LISTEN=TCP-L:18514,fork,reuseaddr
Environment=SOCKS_PROXY=SOCKS4A:127.0.0.1
Environment=SOCKS_PORT=socksport=9050
Environment=SOCAT_REMOTE=
ExecStart=/usr/bin/socat ${SOCAT_LISTEN} ${SOCKS_PROXY}:${SOCAT_REMOTE},${SOCKS_PORT}
ExecStop=/bin/kill -s QUIT ${MAINPID}
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now socat.service
systemctl restart socat.service

### Install HAProxy ##########################################################

apt-get install -yq --no-install-recommends \
    haproxy
systemctl enable --now haproxy.service

cat << 'EOF' > /etc/haproxy/haproxy.cfg
global
  log /dev/log local0 info
  chroot /var/lib/haproxy
  user haproxy
  group haproxy
  daemon

defaults
  log global
  mode http
  option httplog
  option dontlognull
  timeout connect 30000
  timeout client 60000
  timeout server 60000

frontend headscale
  bind *:8514
  default_backend headscale

backend headscale
  option httpchk GET /health HTTP/1.1\r\nHost:\ www.example.com

  server primary headscale:8514 check inter 5000 rise 1 fall 2 init-addr 100.64.0.1
  server secondary localhost:18514 backup check inter 5000 rise 1 fall 2
EOF
systemctl restart haproxy.service

### Install Tailscale #########################################################

apt-get install -yq --no-install-recommends \
    curl lsb-release

OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
VERSION=$(lsb_release -sc | tr '[:upper:]' '[:lower:]')

curl "https://pkgs.tailscale.com/stable/$OS/$VERSION.noarmor.gpg" | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl "https://pkgs.tailscale.com/stable/$OS/$VERSION.tailscale-keyring.list" | tee /etc/apt/sources.list.d/tailscale.list

apt-get update
apt-get install -yq --no-install-recommends \
    tailscale tailscale-archive-keyring
systemctl enable --now tailscaled.service

cat << 'EOF' > /lib/systemd/system/tailscaled.service
[Unit]
Description=Tailscale node agent
Documentation=https://tailscale.com/kb/
Wants=network-pre.target
After=network-pre.target NetworkManager.service systemd-resolved.service

[Service]
EnvironmentFile=/etc/default/tailscaled
ExecStartPre=/usr/sbin/tailscaled --cleanup
ExecStart=/usr/sbin/tailscaled --no-logs-no-support --state=mem: --socket=/run/tailscale/tailscaled.sock --port=${PORT} $FLAGS
ExecStopPost=/usr/sbin/tailscaled --cleanup

Restart=on-failure

RuntimeDirectory=tailscale
RuntimeDirectoryMode=0755
StateDirectory=tailscale
StateDirectoryMode=0700
CacheDirectory=tailscale
CacheDirectoryMode=0750
Type=notify

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl restart tailscaled.service

### Connect Tailscale #########################################################

