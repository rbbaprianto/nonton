#!/bin/bash

# Generate SSL
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/certs/key.pem \
  -out /etc/ssl/certs/cert.pem \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Nonton/CN=nonton.fly.dev"

# Generate API keys
declare -A apps=(
  ["JELLYFIN"]="/etc/jellyfin/config.json"
  ["SONARR"]="/etc/sonarr/config.xml"
  ["RADARR"]="/etc/radarr/config.xml"
  ["BAZARR"]="/etc/bazarr/config.ini"
)

for app in "${!apps[@]}"; do
  if [ -z "${!app}" ]; then
    new_key=$(uuidgen)
    export "${app}_API_KEY"="$new_key"
    echo "${app}_API_KEY=$new_key" >> /tmp/api_keys.txt
    sed -i "s/{{${app}_API_KEY}}/$new_key/g" "${apps[$app]}"
  fi
done

# Encrypt and send keys
if [ -f /tmp/api_keys.txt ]; then
  openssl enc -aes-256-cbc -salt -pass pass:$ENCRYPTION_PWD \
    -in /tmp/api_keys.txt \
    -out /tmp/api_keys.enc
  
  python3 /scripts/send_keys.py $ENCRYPTION_PWD
  rm /tmp/api_keys.*
fi

# Start services
tailscale up --authkey=$TAILSCALE_AUTHKEY --hostname=nonton
/usr/bin/supervisord -n