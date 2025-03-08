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

# Tambahkan package
RUN apt-get install -y jq gh

# Install dependencies untuk monitoring
RUN apt-get update && apt-get install -y \
    python3-distutils \
    python3-apt \
    && rm -rf /var/lib/apt/lists/*

# Install python-telegram-bot dengan versi spesifik
RUN pip3 install python-telegram-bot[webhooks]==20.3 pyyaml requests cryptography

# Setup Tailscale dan Supervisor dengan optimasi memori
RUN mkdir -p /var/run/tailscale /var/lib/tailscale /var/log/supervisor && \
    # Konfigurasi Jellyfin dengan limit resource
    echo "[program:jellyfin]\n\
command = jellyfin --nowebclient --ffmpeg-path=/usr/bin/ffmpeg --transcoding-threads=2\n\
autostart = true\n\
autorestart = true\n\
environment = JELLYFIN_FFMPEG_OPTIONS='-threads 2',JELLYFIN_MEMORY_LIMIT='512M'\n\
priority = 100\n\
stdout_logfile = /var/log/supervisor/jellyfin.log\n\
stderr_logfile = /var/log/supervisor/jellyfin-error.log\n\n" >> /etc/supervisord.conf && \

    # Konfigurasi qBittorrent dengan limit download
    echo "[program:qbittorrent]\n\
command = qbittorrent-nox --webui-port=8080 --max-concurrent-downloads=3\n\
autostart = true\n\
autorestart = true\n\
priority = 200\n\
stdout_logfile = /var/log/supervisor/qbittorrent.log\n\
stderr_logfile = /var/log/supervisor/qbittorrent-error.log\n\n" >> /etc/supervisord.conf && \

    # Konfigurasi Tailscale
    echo "[program:tailscale]\n\
command = tailscale up --authkey=%(ENV_TAILSCALE_AUTHKEY)s --hostname=fly-app\n\
autostart = true\n\
autorestart = true\n\
startretries = 5\n\
environment = TAILSCALE_AUTHKEY=\"%(ENV_TAILSCALE_AUTHKEY)s\"\n\
stdout_logfile = /var/log/supervisor/tailscale.log\n\
stderr_logfile = /var/log/supervisor/tailscale-error.log\n\n" >> /etc/supervisord.conf && \

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
    # Setup direktori dan permission
    mkdir -p /var/lib/tailscale && \
    mkdir -p /var/log/{jellyfin,qbittorrent,aria2} && \
    # Optimasi ulimit
    echo "* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf && \
    echo "vm.swappiness=10" >> /etc/sysctl.conf

# Expose port yang diperlukan
EXPOSE 80 443 8080 3478 41641/udp

# Flyctl authentication
ENV FLYCTL_INSTALL="/root/.fly"
ENV PATH="$FLYCTL_INSTALL/bin:$PATH"
RUN flyctl auth token || true  # Will prompt for token if not set

# Entrypoint untuk handling shutdown
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

# Health check
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl --fail http://localhost:80 || exit 1
