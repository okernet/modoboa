# Modoboa (Production) via Docker Compose — No bind mounts

This setup runs:

- Modoboa (web UI + API)
- PostgreSQL (Modoboa DB)
- Redis (queues)
- Postfix (SMTP: 25/587/465)
- Dovecot (IMAP/POP3 + LMTP)
- Nginx reverse proxy (Modoboa web UI)
- Let’s Encrypt certificates using `lego` (HTTP-01 webroot)

It uses **only Docker named volumes** (no host paths).

All service scripts are baked into custom Docker images (built via CI):

| Image | Purpose |
|---|---|
| `okernet/modoboa` | Modoboa app + init/config scripts |
| `okernet/modoboa-postfix` | Postfix MTA |
| `okernet/modoboa-dovecot` | Dovecot IMAP/POP3 |
| `okernet/modoboa-tls-bootstrap` | Self-signed cert bootstrap |
| `okernet/modoboa-nginx` | Nginx reverse proxy |
| `okernet/modoboa-acme` | Let's Encrypt cert management |

## 0) Requirements

1. A public server with ports open:
- Web: `80`, `443`
- Mail: `25`, `587`, `465`, `143`, `993` (and optionally `110`, `995`, `4190`)
2. DNS records (minimum):
- `A/AAAA` for `mail.example.com` → your server IP
- `MX` for `example.com` → `mail.example.com`
3. For deliverability (recommended):
- Reverse DNS (PTR) for your server IP → `mail.example.com`
- SPF, DKIM, DMARC (configure after the stack is running)

## 1) Configure environment variables (no .env file required)

In your shell, export the values you want:

  ```bash
  export TZ="Europe/London"

  export WEB_FQDN="mail.example.com"     # Web UI + TLS certificate name
  export MAIL_FQDN="mail.example.com"    # SMTP banner / hostname
  export PRIMARY_DOMAIN="example.com"    # used for postmaster@ domain in LMTP

  export DB_NAME="modoboa"
  export DB_USER="modoboa"
  export DB_PASSWORD="REPLACE_WITH_A_STRONG_PASSWORD"
  export DB_URL="postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}"

  export DJANGO_SECRET_KEY="REPLACE_WITH_A_LONG_RANDOM_SECRET"
  export LE_EMAIL="admin@example.com"

  # Image tags you publish to Docker Hub
  export MODOBOA_TAG="latest"
  export POSTFIX_TAG="latest"
  export DOVECOT_TAG="latest"
  export TLS_BOOTSTRAP_TAG="latest"
  export NGINX_TAG="latest"
  export ACME_TAG="latest"
