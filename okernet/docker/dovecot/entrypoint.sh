#!/usr/bin/env sh
set -eu

# Expecting Modoboa-generated Dovecot config at /shared/modoboa/dovecot
CFG_DIR="/shared/modoboa/dovecot"

if [ ! -d "${CFG_DIR}" ]; then
  echo "ERROR: Missing ${CFG_DIR} (expected Dovecot config shared from Modoboa)." >&2
  echo "       Provide generated config via the shared volume /shared/modoboa." >&2
  exit 1
fi

# Install provided config
mkdir -p /etc/dovecot
cp -a "${CFG_DIR}/." /etc/dovecot/

TLS_CERT_PATH="${TLS_CERT_PATH:-/etc/certs/live/fullchain.pem}"
TLS_KEY_PATH="${TLS_KEY_PATH:-/etc/certs/live/key.pem}"

# If your config uses these paths, great; otherwise this is harmless.
if [ -f "${TLS_CERT_PATH}" ] && [ -f "${TLS_KEY_PATH}" ]; then
  : # no-op; your config should reference these or you can template them yourself
fi

# Foreground mode
exec dovecot -F
