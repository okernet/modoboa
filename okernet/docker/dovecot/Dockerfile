# syntax=docker/dockerfile:1.6
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      dovecot-core \
      dovecot-imapd \
      dovecot-pop3d \
      dovecot-lmtpd \
      dovecot-managesieved \
      dovecot-sieve \
      dovecot-pgsql \
      ca-certificates \
      tini \
      netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Common vmail uid/gid
RUN groupadd -g 5000 vmail \
 && useradd -u 5000 -g vmail -d /var/lib/mail -s /usr/sbin/nologin vmail \
 && mkdir -p /var/lib/mail /run/dovecot \
 && chown -R vmail:vmail /var/lib/mail /run/dovecot

COPY okernet/docker/dovecot/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 143 993 110 995 4190
VOLUME ["/var/lib/mail", "/run/dovecot", "/shared/modoboa", "/etc/certs"]

ENTRYPOINT ["/usr/bin/tini","--","/entrypoint.sh"]
