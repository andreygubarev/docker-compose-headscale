FROM tailscale/tailscale:latest

RUN apk add --no-cache socat

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV TS_PORTFORWARD=

ENTRYPOINT ["/entrypoint.sh"]
