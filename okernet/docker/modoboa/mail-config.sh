#!/bin/sh
set -e

test -f /data/instance/manage.py || { echo "Missing /data/instance. Run modoboa-init first."; exit 1; }

mkdir -p /shared/modoboa/postfix /shared/modoboa/dovecot

echo "Generating Postfix SQL map files using Modoboa tooling..."
cd /data/instance

python manage.py generate_postfix_maps --destdir /shared/modoboa/postfix

echo "Writing Postfix main.cf + master.cf..."
cat > /shared/modoboa/postfix/main.cf <<EOF
# Core identity
myhostname = ${MAIL_FQDN}
myorigin = \$myhostname
inet_interfaces = all
inet_protocols = all
mynetworks = 127.0.0.0/8 [::1]/128
smtpd_banner = \$myhostname ESMTP
biff = no
append_dot_mydomain = no
unknown_local_recipient_reject_code = 550
unverified_recipient_reject_code = 550

# TLS (certs volume mounted at /etc/certs)
smtpd_tls_key_file = /etc/certs/live/key.pem
smtpd_tls_cert_file = /etc/certs/live/fullchain.pem
smtpd_tls_security_level = may
smtpd_tls_loglevel = 1
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_security_level = may

# SASL auth via Dovecot (socket in Postfix chroot)
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_authenticated_header = yes

# Proxy maps (Modoboa-generated sql-*.cf)
proxy_read_maps =
    proxy:unix:passwd.byname
    proxy:pgsql:/etc/postfix/sql-domains.cf
    proxy:pgsql:/etc/postfix/sql-domain-aliases.cf
    proxy:pgsql:/etc/postfix/sql-aliases.cf
    proxy:pgsql:/etc/postfix/sql-relaydomains.cf
    proxy:pgsql:/etc/postfix/sql-maintain.cf
    proxy:pgsql:/etc/postfix/sql-relay-recipient-verification.cf
    proxy:pgsql:/etc/postfix/sql-sender-login-map.cf
    proxy:pgsql:/etc/postfix/sql-spliteddomains-transport.cf
    proxy:pgsql:/etc/postfix/sql-transport.cf

# Deliver to Dovecot over LMTP socket
virtual_transport = lmtp:unix:private/dovecot-lmtp
virtual_mailbox_domains = proxy:pgsql:/etc/postfix/sql-domains.cf
virtual_alias_domains = proxy:pgsql:/etc/postfix/sql-domain-aliases.cf
virtual_alias_maps = proxy:pgsql:/etc/postfix/sql-aliases.cf

relay_domains = proxy:pgsql:/etc/postfix/sql-relaydomains.cf
transport_maps =
    proxy:pgsql:/etc/postfix/sql-transport.cf
    proxy:pgsql:/etc/postfix/sql-spliteddomains-transport.cf

# Recipient restrictions (from Modoboa docs)
smtpd_recipient_restrictions =
    permit_mynetworks
    permit_sasl_authenticated
    check_recipient_access
    proxy:pgsql:/etc/postfix/sql-maintain.cf
    proxy:pgsql:/etc/postfix/sql-relay-recipient-verification.cf
    reject_unverified_recipient
    reject_unauth_destination
    reject_non_fqdn_sender
    reject_non_fqdn_recipient
    reject_non_fqdn_helo_hostname

smtpd_sender_login_maps = proxy:pgsql:/etc/postfix/sql-sender-login-map.cf
EOF

# Minimal master.cf enabling submission(587) and smtps(465)
cat > /shared/modoboa/postfix/master.cf <<EOF
smtp      inet  n       -       y       -       -       smtpd
submission inet n       -       y       -       -       smtpd
    -o syslog_name=postfix/submission
    -o smtpd_tls_security_level=encrypt
    -o smtpd_sasl_auth_enable=yes
    -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
smtps     inet  n       -       y       -       -       smtpd
    -o syslog_name=postfix/smtps
    -o smtpd_tls_wrappermode=yes
    -o smtpd_sasl_auth_enable=yes
    -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
EOF

chmod 0640 /shared/modoboa/postfix/*.cf || true

echo "Writing Dovecot config..."
cat > /shared/modoboa/dovecot/dovecot.conf <<EOF
protocols = imap pop3 lmtp sieve
listen = *
disable_plaintext_auth = yes
auth_mechanisms = plain login

# TLS (certs volume mounted at /etc/certs)
ssl = required
ssl_cert = </etc/certs/live/fullchain.pem
ssl_key = </etc/certs/live/key.pem
ssl_min_protocol = TLSv1.2

# Mail storage
mail_location = maildir:~/Maildir

# SQL auth (Modoboa schema)
passdb {
    driver = sql
    args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
    driver = sql
    args = /etc/dovecot/dovecot-sql.conf.ext
}

# Provide auth + LMTP sockets inside Postfix spool (shared volume mounted at /var/spool/postfix)
service auth {
    unix_listener /var/spool/postfix/private/auth {
        mode = 0666
    }
}
service lmtp {
    unix_listener /var/spool/postfix/private/dovecot-lmtp {
        mode = 0666
    }
}

protocol lmtp {
    postmaster_address = postmaster@${PRIMARY_DOMAIN}
    mail_plugins = \$mail_plugins sieve quota
}

plugin {
    sieve = file:~/sieve;active=~/.dovecot.sieve
    sieve_dir = ~/sieve
    quota = maildir:User quota
}
EOF

# PostgreSQL queries from Modoboa docs, adapted to constants for uid/gid/home.
cat > /shared/modoboa/dovecot/dovecot-sql.conf.ext <<EOF
driver = pgsql
connect = host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} password=${DB_PASSWORD}
default_pass_scheme = CRYPT

user_query = \
    SELECT '/var/lib/mail/%d/%n' AS home, ${VMAIL_UID} as uid, \
    ${VMAIL_GID} as gid, '*:bytes=' || mb.quota || 'M' AS quota_rule \
    FROM admin_mailbox mb \
    INNER JOIN admin_domain dom ON mb.domain_id=dom.id \
    INNER JOIN core_user u ON u.id=mb.user_id \
    WHERE (mb.is_send_only IS NOT TRUE OR '%s' NOT IN ('imap', 'pop3', 'lmtp')) \
    AND mb.address='%n' AND dom.name='%d'

password_query = \
    SELECT email AS user, password, '/var/lib/mail/%d/%n' AS userdb_home, \
    ${VMAIL_UID} AS userdb_uid, ${VMAIL_GID} AS userdb_gid, \
    '*:bytes=' || mb.quota || 'M' AS userdb_quota_rule \
    FROM core_user u \
    INNER JOIN admin_mailbox mb ON u.id=mb.user_id \
    INNER JOIN admin_domain dom ON mb.domain_id=dom.id \
    WHERE (mb.is_send_only IS NOT TRUE OR '%s' NOT IN ('imap', 'pop3')) \
    AND email='%u' AND is_active AND dom.enabled

iterate_query = SELECT email AS user FROM core_user WHERE is_active
EOF

chmod 0640 /shared/modoboa/dovecot/* || true

echo "mail-config done."
