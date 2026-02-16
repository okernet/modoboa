#!/bin/sh
set -e

mkdir -p /certs /certs/live /var/www/acme/.well-known/acme-challenge

issue() {
  lego --path /certs \
    --email "${LE_EMAIL}" \
    --domains "${WEB_FQDN}" \
    --http --http.webroot /var/www/acme \
    --accept-tos run || true

  # Link "live" files for services to consume
  # lego stores certs under /certs/certificates/
  ln -sf "/certs/certificates/${WEB_FQDN}.crt" /certs/live/fullchain.pem || true
  ln -sf "/certs/certificates/${WEB_FQDN}.key" /certs/live/key.pem || true
}

renew() {
  lego --path /certs \
    --email "${LE_EMAIL}" \
    --domains "${WEB_FQDN}" \
    --http --http.webroot /var/www/acme \
    renew --days 30 || true

  ln -sf "/certs/certificates/${WEB_FQDN}.crt" /certs/live/fullchain.pem || true
  ln -sf "/certs/certificates/${WEB_FQDN}.key" /certs/live/key.pem || true
}

issue
while true; do
  renew
  sleep 12h
done
