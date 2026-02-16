#!/bin/sh
set -e

if [ -f /data/instance/manage.py ]; then
  echo "Modoboa instance already exists; skipping init."
  exit 0
fi

echo "Creating Modoboa instance..."
mkdir -p /data/instance

modoboa-admin.py deploy \
  --directory /data/instance \
  --dburl "${DB_URL}" \
  --domain "${WEB_FQDN}" \
  --collectstatic

echo "Hardening Django settings (ALLOWED_HOSTS / proxy SSL header)..."
export SETTINGS_PATH="/data/instance/instance/settings.py"
python /scripts/django-hardening.py

echo "Migrating + collecting static..."
cd /data/instance
python manage.py migrate --noinput
python manage.py collectstatic --noinput

echo "Init done. Next: run mail-config, then start the stack."
