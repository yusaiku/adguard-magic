FROM alpine:3.20

# Environment variables (can be overridden at runtime)
ENV DOMAIN="" \
    EMAIL="" \
    BUNNY_API_KEY="" \
    ACME_SERVER="letsencrypt" \
    CERT_DIR="/certs" \
    CONF_DIR="/opt/adguardhome/conf" \
    WORK_DIR="/opt/adguardhome/work" \
    ACME_HOME="/root/.acme.sh"

# Install dependencies
RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    openssl \
    tzdata \
    gettext \
    supercronic \
    coreutils

# Install acme.sh
RUN curl https://get.acme.sh | sh -s email=${EMAIL:-placeholder@example.com} && \
    ln -s /root/.acme.sh/acme.sh /usr/local/bin/acme.sh

# Install latest AdGuard Home binary
RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -L "https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_${ARCH}.tar.gz" | \
    tar xz -C /tmp && \
    mv /tmp/AdGuardHome/AdGuardHome /usr/local/bin/adguardhome && \
    rm -rf /tmp/AdGuardHome

# Create directories
RUN mkdir -p ${CERT_DIR} ${CONF_DIR} ${WORK_DIR} /etc/cron.d

# Copy files
COPY entrypoint.sh /entrypoint.sh
COPY adguard-template.yaml /adguard-template.yaml
COPY renew-cron.sh /renew-cron.sh

RUN chmod +x /entrypoint.sh /renew-cron.sh

# Default volumes (user should mount persistent ones in Bunny)
VOLUME ["${CERT_DIR}", "${CONF_DIR}", "${WORK_DIR}"]

# Expose ports for DNS, DoT, DoH, Web UI
EXPOSE 53/tcp 53/udp 853/tcp 443/tcp 3000/tcp

ENTRYPOINT ["/entrypoint.sh"]
CMD []