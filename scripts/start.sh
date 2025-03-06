#!/bin/bash

# Generate SSL cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/certs/key.pem \
  -out /etc/ssl/certs/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Company/CN=nonton.fly.dev"

# Generate config files from templates
envsubst < /etc/jellyfin/config.json.template > /etc/jellyfin/config.json
envsubst < /etc/radarr/config.xml.template > /etc/radarr/config.xml
envsubst < /etc/qbittorrent/qBittorrent.conf.template > /etc/qbittorrent/qBittorrent.conf

# Start Tailscale
tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=nonton

# Start semua services
supervisord -n
