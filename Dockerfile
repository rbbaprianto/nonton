FROM ubuntu:22.04

ARG ENCRYPTION_PWD
ENV ENCRYPTION_PWD=$ENCRYPTION_PWD

# Install dependencies dan tambahkan repository
RUN apt-get update && \
    apt-get install -y curl gnupg software-properties-common && \
    # Tambahkan repo Jellyfin
    curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /usr/share/keyrings/jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/jellyfin.gpg] https://repo.jellyfin.org/ubuntu jammy main" | tee /etc/apt/sources.list.d/jellyfin.list && \
    # Tambahkan repo Tailscale
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    # Tambahkan PPA qBittorrent
    add-apt-repository ppa:qbittorrent-team/qbittorrent-stable -y && \
    apt-get update && \
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