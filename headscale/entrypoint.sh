#!/bin/sh

cat << EOF > /etc/headscale/config.yaml
server_url: ${HEADSCALE_SERVER_URL}
listen_addr: ${HEADSCALE_LISTEN_ADDR}

db_type: ${HEADSCALE_DB_TYPE}
db_path: ${HEADSCALE_DB_PATH}

ip_prefixes:
  - 100.64.0.0/10

dns_config:
  override_local_dns: true
  nameservers:
    - 1.1.1.1
  magic_dns: true
  base_domain: ${HEADSCALE_BASE_DOMAIN}

derp:
  urls:
    - https://controlplane.tailscale.com/derpmap/default
  auto_update_enabled: true
  update_frequency: 24h

private_key_path: /var/lib/headscale/private.key
noise:
  private_key_path: /var/lib/headscale/noise_private.key

disable_check_updates: true
EOF

headscale "$@"
