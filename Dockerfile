FROM ubuntu:22.04

ARG ENCRYPTION_PWD
ENV ENCRYPTION_PWD=$ENCRYPTION_PWD \
    JELLYFIN_DATA_DIR="/media" \
    TS_STATE_DIR="/var/lib/tailscale" \
    DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    software-properties-common \
    cron \
    && rm -rf /var/lib/apt/lists/*

# Add repositories
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/jellyfin.gpg] https://repo.jellyfin.org/ubuntu jammy main" > /etc/apt/sources.list.d/jellyfin.list && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /etc/apt/keyrings/tailscale.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    add-apt-repository ppa:qbittorrent-team/qbittorrent-stable -y

# Install main packages
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
RUN pip3 install --no-cache-dir requests python-telegram-bot==13.7

# Setup directories and permissions
RUN mkdir -p \
    /var/run/tailscale \
    $TS_STATE_DIR \
    /var/log/supervisor \
    $JELLYFIN_DATA_DIR && \
    chmod 777 $JELLYFIN_DATA_DIR && \
    echo "* soft nofile 65536\n* hard nofile 65536" >> /etc/security/limits.conf && \
    echo "vm.swappiness=10" >> /etc/sysctl.conf

# Supervisor configuration
COPY config/supervisord.conf /etc/supervisor/supervisord.conf

# Nginx configuration
COPY config/nginx.conf /etc/nginx/sites-available/default
RUN rm /etc/nginx/sites-enabled/default && \
    ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/* && \
    crontab -l | { cat; echo "*/5 * * * * /usr/bin/python3 /scripts/disk_monitor.py"; } | crontab -

# Expose ports
EXPOSE 80 443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=1m \
  CMD curl -f http://localhost:80/healthz || exit 1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]