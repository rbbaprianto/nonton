#!/bin/bash

# Fungsi untuk generate API key dan update config
generate_api_key() {
  local app_name=$1
  local config_file=$2
  local key_name=$3
  local template_var=$4
  
  if [ -z "${!key_name}" ]; then
    # Generate UUID v4 sebagai API key
    new_key=$(uuidgen)
    export ${key_name}=$new_key
    
    # Update config file
    sed -i "s/${template_var}/${new_key}/g" $config_file
    
    # Log generated key
    echo "======================================================"
    echo "⚠️  AUTO-GENERATED ${app_name} API KEY ⚠️"
    echo "GUNAKAN INI UNTUK GITHUB SECRETS:"
    echo "Nama Secret: ${key_name}"
    echo "Value: ${new_key}"
    echo "======================================================"
  else
    # Gunakan existing key dari environment variable
    sed -i "s/${template_var}/${!key_name}/g" $config_file
  fi
}

# Generate API keys untuk semua aplikasi
generate_api_key "JELLYFIN" "/etc/jellyfin/config.json" "JELLYFIN_API_KEY" "{{JELLYFIN_API_KEY}}"
generate_api_key "SONARR" "/etc/sonarr/config.xml" "SONARR_API_KEY" "{{SONARR_API_KEY}}"
generate_api_key "RADARR" "/etc/radarr/config.xml" "RADARR_API_KEY" "{{RADARR_API_KEY}}"
generate_api_key "BAZARR" "/etc/bazarr/config.ini" "BAZARR_API_KEY" "{{BAZARR_API_KEY}}"

# Generate SSL cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/certs/key.pem \
  -out /etc/ssl/certs/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Company/CN=media-server.fly.dev"

# Generate config file untuk rclone
envsubst < /etc/rclone/rclone.conf.template > /etc/rclone/rclone.conf

# Start Tailscale
tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=media-server

# Start semua services dengan supervisord
exec /usr/bin/supervisord -n
