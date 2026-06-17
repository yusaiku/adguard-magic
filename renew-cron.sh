#!/bin/bash

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting certificate renewal check..."

/root/.acme.sh/acme.sh --cron --home /root/.acme.sh

DOMAIN=${DOMAIN:-example.com}
ACME_DIR="/root/.acme.sh/${DOMAIN}_ecc"
CERT_PATH="/etc/nginx/ssl/fullchain.cer"
KEY_PATH="/etc/nginx/ssl/privkey.pem"

if [ -f "$ACME_DIR/fullchain.cer" ] && [ -f "$ACME_DIR/${DOMAIN}.key" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Copying renewed certificate..."
    cp "$ACME_DIR/fullchain.cer" "$CERT_PATH"
    cp "$ACME_DIR/${DOMAIN}.key" "$KEY_PATH"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Reloading Nginx..."
    nginx -s reload || true

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Certificate renewal completed."
fi
