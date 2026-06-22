FROM alpine:3.20

ENV DOMAIN="" \
    EMAIL="" \
    BUNNY_API_KEY="" \
    ACME_SERVER="letsencrypt" \
    CERT_DIR="/certs" \
    CONF_DIR="/opt/adguardhome/conf" \
    WORK_DIR="/opt/adguardhome/work" \
    ACME_HOME="/root/.acme.sh"

RUN apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    openssl \
    tzdata \
    supercronic

RUN curl https://get.acme.sh | sh && \
    ln -s /root/.acme.sh/acme.sh /usr/local/bin/acme.sh

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') && \
    curl -L "https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_${ARCH}.tar.gz" | \
    tar xz -C /tmp && \
    mv /tmp/AdGuardHome/AdGuardHome /usr/local/bin/adguardhome && \
    rm -rf /tmp/AdGuardHome

RUN mkdir -p ${CERT_DIR} ${CONF_DIR} ${WORK_DIR} /etc/cron.d

COPY entrypoint.sh /entrypoint.sh
COPY renew-cron.sh /renew-cron.sh

RUN chmod +x /entrypoint.sh /renew-cron.sh

VOLUME ["/opt/adguardhome", "/certs"]

EXPOSE 53/tcp 53/udp 853/tcp 443/tcp 3000/tcp

ENTRYPOINT ["/entrypoint.sh"]
