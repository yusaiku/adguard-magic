#!/bin/bash
set -euo pipefail

if [[ -z "${DOMAIN:-}" || -z "${EMAIL:-}" || -z "${BUNNY_API_KEY:-}" ]]; then
    echo "ERROR: DOMAIN, EMAIL und BUNNY_API_KEY müssen gesetzt sein!"
    exit 1
fi

echo "Starting AdGuard Home with automatic Let's Encrypt (Bunny DNS)..."

# WICHTIG: Ordner erstellen (falls Volume leer oder neu)
mkdir -p "${CERT_DIR}" "${CONF_DIR}" "${WORK_DIR}"

export BUNNY_API_KEY="${BUNNY_API_KEY}"

CERT_FULLCHAIN="${CERT_DIR}/fullchain.pem"
CERT_KEY="${CERT_DIR}/privkey.pem"

# Zertifikat prüfen / erneuern
if [[ ! -f "${CERT_FULLCHAIN}" || ! -f "${CERT_KEY}" ]]; then
    echo "Issuing new certificate for ${DOMAIN}..."
    acme.sh --issue \
        --dns dns_bunny \
        -d "${DOMAIN}" \
        --server "${ACME_SERVER}" \
        --fullchain-file "${CERT_FULLCHAIN}" \
        --key-file "${CERT_KEY}" \
        --keylength 4096 || exit 1
else
    echo "Certificate exists, checking renewal..."
    acme.sh --renew \
        -d "${DOMAIN}" \
        --fullchain-file "${CERT_FULLCHAIN}" \
        --key-file "${CERT_KEY}" || true
fi

# Erneuerungs-Cron
cat > /etc/cron.d/renew << 'EOF'
0 3 * * * /renew-cron.sh >> /var/log/renew.log 2>&1
EOF
chmod 0644 /etc/cron.d/renew
supercronic /etc/cron.d/renew &

echo "Starting AdGuard Home..."
exec adguardhome -c "${CONF_DIR}/AdGuardHome.yaml" -w "${WORK_DIR}" --no-check-update
