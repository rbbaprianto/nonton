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

# Install python-telegram-bot dengan versi spesifik
RUN pip3 install python-telegram-bot==13.7 requests cryptography

# Setup Tailscale dan Supervisor
RUN mkdir -p /var/run/tailscale /var/lib/tailscale /var/log/supervisor && \
    # Buat service untuk tailscaled
    echo "[program:tailscale]\n\
command = tailscale up --authkey=%(ENV_TAILSCALE_AUTHKEY)s --hostname=fly-app\n\
autostart = true\n\
autorestart = true\n\
startretries = 5\n\
environment = TAILSCALE_AUTHKEY=\"%(ENV_TAILSCALE_AUTHKEY)s\"\n\
stdout_logfile = /var/log/supervisor/tailscale.log\n\
stderr_logfile = /var/log/supervisor/tailscale-error.log\n" >> /etc/supervisord.conf && \
    # Konfigurasi dasar supervisor
    echo "[supervisord]\n\
nodaemon=true\n\
logfile=/var/log/supervisor/supervisord.log\n\
pidfile=/var/run/supervisord.pid\n\
[include]\n\
files = /etc/supervisor/conf.d/*.conf\n" >> /etc/supervisord.conf

COPY config/ /etc/
COPY scripts/ /scripts/
COPY fly.toml .

RUN chmod +x /scripts/* && \
    mkdir -p /etc/ssl/certs && \
    # Setup direktori yang diperlukan
    mkdir -p /var/lib/tailscale && \
    mkdir -p /var/log/{jellyfin,qbittorrent,aria2}

# Expose port yang diperlukan
EXPOSE 80 443 8080 3478 41641/udp

# Entrypoint untuk handling shutdown
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]