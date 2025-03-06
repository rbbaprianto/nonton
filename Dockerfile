FROM ubuntu:22.04

# Install semua dependencies
RUN apt-get update && \
    apt-get install -y \
    jellyfin \
    qbittorrent-nox \
    aria2 \
    filebrowser \
    netdata \
    tailscale \
    supervisor \
    nginx \
    gettext-base \
    openssl \
    wget \
    unzip && \
    apt-get clean

# Install aplikasi tambahan
RUN wget https://github.com/Radarr/Radarr/releases/download/v4.8.0/Radarr.master.4.8.0.8153.linux-core-x64.zip -O /tmp/radarr.zip && \
    unzip /tmp/radarr.zip -d /opt/ && \
    rm /tmp/radarr.zip

# Setup direktori konfigurasi
RUN mkdir -p /etc/{jellyfin,rclone,aria2,kuma,bot,prowlarr,sonarr,radarr,bazarr,netdata,filebrowser}

# Copy konfigurasi
COPY config/ /etc/
COPY scripts/ /scripts/
COPY .env.example /etc/environment

# Setup permissions
RUN chmod +x /scripts/*.sh && \
    chmod +x /opt/Radarr/Radarr

# Expose ports
EXPOSE 443 8080

CMD ["/scripts/start.sh"]

# Tambahkan di bagian RUN untuk SSL
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/certs/key.pem \
  -out /etc/ssl/certs/cert.pem \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Nonton/CN=nonton.fly.dev"
