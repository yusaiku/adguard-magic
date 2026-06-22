#!/bin/bash
set -euo pipefail

# This script is called by supercronic for automatic renewal
# If renewal happens, it will trigger container restart via pkill (Bunny auto-restarts)

DOMAIN="${DOMAIN}"
CERT_DIR="${CERT_DIR:-/certs}"
ACME_SERVER="${ACME_SERVER:-letsencrypt}"

CERT_FULLCHAIN="${CERT_DIR}/fullchain.pem"
CERT_KEY="${CERT_DIR}/privkey.pem"

echo "$(date): Checking/renewing certificate for ${DOMAIN}..."

export BUNNY_API_KEY="${BUNNY_API_KEY}"

acme.sh --renew \
    -d "${DOMAIN}" \
    --fullchain-file "${CERT_FULLCHAIN}" \
    --key-file "${CERT_KEY}" \
    --server "${ACME_SERVER}" \
    --reloadcmd "echo 'Certificate renewed or checked. AdGuard will auto-reload file paths.'" || true

echo "$(date): Renewal check complete."
