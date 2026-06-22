#!/bin/bash
set -euo pipefail

# Required env vars check
if [[ -z "${DOMAIN:-}" ]]; then
    echo "ERROR: DOMAIN environment variable is required (e.g. dns.example.com)"
    exit 1
fi
if [[ -z "${EMAIL:-}" ]]; then
    echo "ERROR: EMAIL environment variable is required for ACME"
    exit 1
fi
if [[ -z "${BUNNY_API_KEY:-}" ]]; then
    echo "ERROR: BUNNY_API_KEY environment variable is required for Bunny DNS challenge"
    exit 1
fi

echo "Starting AdGuard Home with ACME (Bunny DNS) for domain: $DOMAIN"

# Ensure directories exist inside mounted volumes
mkdir -p "${CERT_DIR}" "${CONF_DIR}" "${WORK_DIR}"

# Setup acme.sh account if not exists
if [[ ! -f "${ACME_HOME}/account.conf" ]]; then
    echo "Registering ACME account..."
    acme.sh --register-account -m "${EMAIL}" --server "${ACME_SERVER}"
fi

# Export for acme.sh Bunny provider
export BUNNY_API_KEY="${BUNNY_API_KEY}"

CERT_FULLCHAIN="${CERT_DIR}/fullchain.pem"
CERT_KEY="${CERT_DIR}/privkey.pem"

# Issue certificate if not present or needs renewal
if [[ ! -f "${CERT_FULLCHAIN}" || ! -f "${CERT_KEY}" ]]; then
    echo "Issuing new certificate for ${DOMAIN} via Bunny DNS..."
    acme.sh --issue \
        --dns dns_bunny \
        -d "${DOMAIN}" \
        --server "${ACME_SERVER}" \
        --fullchain-file "${CERT_FULLCHAIN}" \
        --key-file "${CERT_KEY}" \
        --keylength 4096 \
        --force || {
            echo "ERROR: Certificate issuance failed. Check DOMAIN, BUNNY_API_KEY and DNS propagation."
            exit 1
        }
    echo "Certificate issued successfully."
else
    echo "Certificate already exists, checking for renewal..."
    # Try renew (non-fatal if not due)
    acme.sh --renew \
        -d "${DOMAIN}" \
        --fullchain-file "${CERT_FULLCHAIN}" \
        --key-file "${CERT_KEY}" \
        --server "${ACME_SERVER}" || true
fi

# Generate AdGuard config from template (only if not exists or force)
CONFIG_FILE="${CONF_DIR}/AdGuardHome.yaml"
if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "Generating initial AdGuardHome.yaml with encryption enabled..."
    export DOMAIN CERT_DIR
    envsubst < /adguard-template.yaml > "${CONFIG_FILE}"
else
    echo "Using existing AdGuardHome.yaml (encryption section should already be set)"
fi

# Setup renewal cron with supercronic (runs in background)
echo "Setting up automatic certificate renewal..."
cat > /etc/cron.d/renew << 'EOF'
0 3 * * * /renew-cron.sh >> /var/log/renew.log 2>&1
EOF
chmod 0644 /etc/cron.d/renew

# Start supercronic in background for renewal
supercronic /etc/cron.d/renew &

echo "Starting AdGuard Home..."
exec adguardhome -c "${CONFIG_FILE}" -w "${WORK_DIR}" --no-check-update
