# syntax=docker/dockerfile:1.6
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      postfix \
      postfix-pgsql \
      postfix-ldap \
      ca-certificates \
      tini \
      netcat-openbsd \
      rsyslog \
    && rm -rf /var/lib/apt/lists/*

COPY okernet/docker/postfix/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25 587 465
VOLUME ["/var/spool/postfix", "/shared/modoboa", "/etc/certs"]

ENTRYPOINT ["/usr/bin/tini","--","/entrypoint.sh"]
