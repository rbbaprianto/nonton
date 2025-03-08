FROM ubuntu:22.04

ARG ENCRYPTION_PWD
ENV ENCRYPTION_PWD=$ENCRYPTION_PWD

RUN apt-get update && \
    apt-get install -y \
    jellyfin \
    qbittorrent-nox \
    aria2 \
    tailscale \
    supervisor \
    nginx \
    openssl \
    uuid-runtime \
    python3 \
    python3-pip \
    && apt-get clean

RUN pip3 install python-telegram-bot==13.7 requests cryptography

COPY config/ /etc/
COPY scripts/ /scripts/
COPY fly.toml .

RUN chmod +x /scripts/* && \
    mkdir -p /etc/ssl/certs

EXPOSE 80 443 8080

CMD ["/scripts/start.sh"]