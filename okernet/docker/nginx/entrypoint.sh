#!/bin/sh
set -e

cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    server_name ${WEB_FQDN};

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/acme;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ${WEB_FQDN};

    ssl_certificate     /etc/certs/live/fullchain.pem;
    ssl_certificate_key /etc/certs/live/key.pem;

    # Static (collected by modoboa-init)
    location /static/ {
        alias /data/instance/static/;
        expires 30d;
        add_header Cache-Control "public";
    }

    location / {
        proxy_pass http://modoboa:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

exec nginx -g "daemon off;"
