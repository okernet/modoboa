#!/usr/bin/env sh
set -eu

INSTANCE_PATH="${MODOBOA_INSTANCE_PATH:-/data/instance}"
PORT="${PORT:-8000}"
WORKERS="${GUNICORN_WORKERS:-2}"
THREADS="${GUNICORN_THREADS:-2}"
TIMEOUT="${GUNICORN_TIMEOUT:-60}"

if [ ! -f "${INSTANCE_PATH}/manage.py" ]; then
  cat >&2 <<EOM
ERROR: Modoboa instance not found at: ${INSTANCE_PATH}
Expected ${INSTANCE_PATH}/manage.py.

Typical first-run sequence:
  1) Run modoboa-admin.py deploy (in an init job/container)
  2) Run migrations/collectstatic
  3) Start this container

This image includes modoboa-admin.py. Example:
  modoboa-admin.py deploy ${INSTANCE_PATH} --domain your.mail.fqdn --dburl default:postgresql://...

EOM
  exit 1
fi

cd "${INSTANCE_PATH}"

# Optional safety: run migrations automatically if you set MODOBOA_AUTO_MIGRATE=1
if [ "${MODOBOA_AUTO_MIGRATE:-0}" = "1" ]; then
  python manage.py migrate --noinput || true
  python manage.py collectstatic --noinput || true
fi

exec gunicorn \
  --bind "0.0.0.0:${PORT}" \
  --workers "${WORKERS}" \
  --threads "${THREADS}" \
  --timeout "${TIMEOUT}" \
  --access-logfile "-" \
  --error-logfile "-" \
  instance.wsgi:application
