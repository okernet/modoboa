#!/bin/sh
set -e

mkdir -p /certs/live

if [ ! -s /certs/live/fullchain.pem ] || [ ! -s /certs/live/key.pem ]; then
  echo "No cert found yet; generating short-lived self-signed cert for ${WEB_FQDN}..."
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3 -nodes \
    -keyout /certs/live/key.pem \
    -out /certs/live/fullchain.pem \
    -subj "/CN=${WEB_FQDN}"
  chmod 600 /certs/live/key.pem
else
  echo "Cert already present; skipping bootstrap."
fi
