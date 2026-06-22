#!/bin/bash
set -euo pipefail

if [[ -z "${DOMAIN:-}" || -z "${EMAIL:-}" || -z "${BUNNY_API_KEY:-}" ]]; then
    echo "ERROR: DOMAIN, EMAIL und BUNNY_API_KEY müssen gesetzt sein!"
    exit 1
fi

echo "Starting AdGuard Home with automatic Let's Encrypt (Bunny DNS)..."

export BUNNY_API_KEY="${BUNNY_API_KEY}"

CERT_FULLCHAIN="${CERT_DIR}/fullchain.pem"
CERT_KEY="${CERT_DIR}/privkey.pem"

# Zertifikat ausstellen oder erneuern
if [[ ! -f "${CERT_FULLCHAIN}" || ! -f "${CERT_KEY}" ]]; then
    echo "Issuing certificate for ${DOMAIN}..."
    acme.sh --issue \
        --dns dns_bunny \
        -d "${DOMAIN}" \
        --server "${ACME_SERVER}" \
        --fullchain-file "${CERT_FULLCHAIN}" \
        --key-file "${CERT_KEY}" \
        --keylength 4096 || {
            echo "ERROR: Certificate issuance failed."
            exit 1
        }
else
    echo "Certificate exists, checking renewal..."
    acme.sh --renew \
        -d "${DOMAIN}" \
        --fullchain-file "${CERT_FULLCHAIN}" \
        --key-file "${CERT_KEY}" || true
fi

# Erneuerungs-Cron starten
cat > /etc/cron.d/renew << 'EOF'
0 3 * * * /renew-cron.sh >> /var/log/renew.log 2>&1
EOF
chmod 0644 /etc/cron.d/renew
supercronic /etc/cron.d/renew &

echo "Starting AdGuard Home (will create clean default config)..."
exec adguardhome -c "${CONF_DIR}/AdGuardHome.yaml" -w "${WORK_DIR}" --no-check-update
