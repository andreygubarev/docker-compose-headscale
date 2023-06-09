FROM headscale/headscale:latest

RUN apt-get update \
    && apt-get install -yq --no-install-recommends \
        ca-certificates \
        curl \
        locales \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.UTF-8

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

ENV HEADSCALE_BASE_DOMAIN=example.com
ENV HEADSCALE_SERVER_URL=http://127.0.0.1:8514
ENV HEADSCALE_LISTEN_ADDR=:8514
ENV HEADSCALE_DB_TYPE=sqlite3
ENV HEADSCALE_DB_PATH=/var/lib/headscale/db.sqlite
RUN mkdir -p /etc/headscale

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8514

HEALTHCHECK CMD ["curl", "-f", "http://localhost:8514/health"]
ENTRYPOINT ["/entrypoint.sh"]
CMD ["serve"]
