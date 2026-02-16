#!/usr/bin/env sh
set -eu

# Expecting Modoboa-generated Postfix config at /shared/modoboa/postfix
CFG_DIR="/shared/modoboa/postfix"

if [ ! -d "${CFG_DIR}" ]; then
  echo "ERROR: Missing ${CFG_DIR} (expected Postfix config shared from Modoboa)." >&2
  echo "       Provide generated config via the shared volume /shared/modoboa." >&2
  exit 1
fi

# Install provided config
cp -a "${CFG_DIR}/." /etc/postfix/

MAIL_FQDN="${MAIL_FQDN:-${MODOBOA_FQDN:-localhost}}"
TLS_CERT_PATH="${TLS_CERT_PATH:-/etc/certs/live/fullchain.pem}"
TLS_KEY_PATH="${TLS_KEY_PATH:-/etc/certs/live/key.pem}"

# Minimal safety defaults (won't override if your config already sets them)
postconf -e "myhostname=${MAIL_FQDN}" || true
postconf -e "smtpd_banner=\$myhostname ESMTP" || true

if [ -f "${TLS_CERT_PATH}" ] && [ -f "${TLS_KEY_PATH}" ]; then
  postconf -e "smtpd_tls_cert_file=${TLS_CERT_PATH}" || true
  postconf -e "smtpd_tls_key_file=${TLS_KEY_PATH}" || true
fi

# Postfix logs to syslog by default; keep rsyslogd running
rsyslogd

postfix check
exec postfix start-fg
