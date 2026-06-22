#!/bin/bash
set -euo pipefail

export BUNNY_API_KEY="${BUNNY_API_KEY}"

acme.sh --renew \
    -d "${DOMAIN}" \
    --fullchain-file "${CERT_DIR}/fullchain.pem" \
    --key-file "${CERT_DIR}/privkey.pem" \
    --server "${ACME_SERVER}" || true
