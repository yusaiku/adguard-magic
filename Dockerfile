FROM debian:13-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    nginx-extras \
    supervisor \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://get.acme.sh | sh -s email=placeholder@example.com

RUN mkdir -p /etc/nginx/ssl /opt/adguardhome /root/.acme.sh

RUN curl -L -o /tmp/adguard.tar.gz https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz && \
    tar -xzf /tmp/adguard.tar.gz -C /opt/adguardhome --strip-components=1 && \
    rm /tmp/adguard.tar.gz

COPY nginx.conf.template /etc/nginx/
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY renew-cron.sh /usr/local/bin/renew-cron.sh

RUN chmod +x /entrypoint.sh /opt/adguardhome/AdGuardHome /usr/local/bin/renew-cron.sh

EXPOSE 80 443 853

ENTRYPOINT ["/entrypoint.sh"]
