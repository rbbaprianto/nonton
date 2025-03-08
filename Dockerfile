FROM ubuntu:22.04

ARG ENCRYPTION_PWD
ENV ENCRYPTION_PWD=$ENCRYPTION_PWD \
    DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    software-properties-common \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add repositories
RUN mkdir -p /etc/apt/keyrings && \
    # Jellyfin
    curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/jellyfin.gpg] https://repo.jellyfin.org/ubuntu jammy main" > /etc/apt/sources.list.d/jellyfin.list && \
    # Tailscale
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /etc/apt/keyrings/tailscale.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    # qBittorrent
    add-apt-repository ppa:qbittorrent-team/qbittorrent-stable -y

# Install packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Python dependencies
RUN pip3 install --no-cache-dir python-telegram-bot==13.7 requests cryptography

# Supervisor configuration
RUN mkdir -p /var/{log/supervisor,run/tailscale,lib/tailscale} && \
    echo "[supervisord]\n\
nodaemon=true\n\
logfile=/var/log/supervisor/supervisord.log\n\
pidfile=/var/run/supervisord.pid\n\
[include]\n\
files = /etc/supervisor/conf.d/*.conf\n\n\
[program:nginx]\n\
command=nginx -g 'daemon off;'\n\
autostart=true\n\
autorestart=true\n\
priority=10\n\
stdout_logfile=/var/log/supervisor/nginx.log\n\
stderr_logfile=/var/log/supervisor/nginx-error.log\n\n\
[program:jellyfin]\n\
command=jellyfin --nowebclient --ffmpeg-path=/usr/bin/ffmpeg --transcoding-threads=2\n\
autostart=true\n\
autorestart=true\n\
environment=JELLYFIN_FFMPEG_OPTIONS='-threads 2'\n\
priority=20\n\
stdout_logfile=/var/log/supervisor/jellyfin.log\n\
stderr_logfile=/var/log/supervisor/jellyfin-error.log\n\n\
[program:qbittorrent]\n\
command=qbittorrent-nox --webui-port=8080 --max-concurrent-downloads=3\n\
autostart=true\n\
autorestart=true\n\
priority=30\n\
stdout_logfile=/var/log/supervisor/qbittorrent.log\n\
stderr_logfile=/var/log/supervisor/qbittorrent-error.log\n\n\
[program:tailscale]\n\
command=tailscale up --authkey=%(ENV_TAILSCALE_AUTHKEY)s --hostname=fly-app\n\
autostart=true\n\
autorestart=true\n\
startretries=5\n\
environment=TAILSCALE_AUTHKEY=\"%(ENV_TAILSCALE_AUTHKEY)s\"\n\
stdout_logfile=/var/log/supervisor/tailscale.log\n\
stderr_logfile=/var/log/supervisor/tailscale-error.log" > /etc/supervisor/supervisord.conf

# Nginx configuration
COPY config/nginx/jellyfin.conf /etc/nginx/sites-available/default
RUN rm /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Scripts and configs
COPY scripts/ /scripts/
RUN chmod +x /scripts/* && \
    mkdir -p /etc/ssl/certs && \
    echo "* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf && \
    echo "vm.swappiness=10" >> /etc/sysctl.conf

# Ports and healthcheck
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
  CMD curl -f http://localhost:80/health_check || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]