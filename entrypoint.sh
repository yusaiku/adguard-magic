#!/bin/bash
set -e

DOMAIN=${DOMAIN:?DOMAIN is required}
EMAIL=${EMAIL:?EMAIL is required}
BUNNY_API_KEY=${BUNNY_API_KEY:?BUNNY_API_KEY is required}

echo "==> Starting AdGuard Magic Container for domain: $DOMAIN"

rm -rf /root/.acme.sh/account.conf /root/.acme.sh/ca /root/.acme.sh/*.key 2>/dev/null || true

echo "==> Trying to issue/renew Let's Encrypt certificate..."
export BUNNY_API_KEY
/root/.acme.sh/acme.sh --register-account -m "$EMAIL" || true

/root/.acme.sh/acme.sh --issue \
    --dns dns_bunny \
    -d "$DOMAIN" \
    --server letsencrypt || echo "Warning: Let's Encrypt failed"

CERT_PATH="/etc/nginx/ssl/fullchain.cer"
KEY_PATH="/etc/nginx/ssl/privkey.pem"
ACME_DIR="/root/.acme.sh/${DOMAIN}_ecc"

if [ -f "$ACME_DIR/fullchain.cer" ] && [ -f "$ACME_DIR/${DOMAIN}.key" ]; then
    mkdir -p /etc/nginx/ssl
    cp "$ACME_DIR/fullchain.cer" "$CERT_PATH"
    cp "$ACME_DIR/${DOMAIN}.key" "$KEY_PATH"
    echo "==> Using Let's Encrypt certificate"
else
    echo "==> Generating self-signed certificate as fallback..."
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$KEY_PATH" -out "$CERT_PATH" -subj "/CN=${DOMAIN}"
fi

envsubst '$DOMAIN' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
