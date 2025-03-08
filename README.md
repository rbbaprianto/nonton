```markdown
# Nonton Media Server

Media server stack terintegrasi untuk streaming, manajemen konten, dan otomasi unduhan. Deploy otomatis ke Fly.io dengan Docker.

## Komponen Utama

### Core Services
- **Jellyfin** (`:8096`) - Streaming media
- **qBittorrent** (`:8080`) - Torrent client
- **Aria2** - Download client HTTP/FTP
- **Sonarr** (`:8989`) - Manajemen series TV
- **Radarr** (`:7878`) - Manajemen film
- **Bazarr** (`:6767`) - Manajemen subtitle

### Infrastruktur
- **Nginx** - Reverse proxy + SSL
- **Tailscale** - Koneksi VPN
- **Supervisord** - Process manager
- **Fly.io** - Deployment platform

## Persyaratan

### GitHub Secrets
| Secret Name               | Contoh Value                     |
|---------------------------|----------------------------------|
| `FLY_API_TOKEN`           | `fly_xxxx`                       |
| `TAILSCALE_AUTHKEY`       | `tskey-auth-xxxx`                |
| `TELEGRAM_BOT_TOKEN`      | `123456:ABC-DEF1234ghIkl-zyx57W2`|
| `TELEGRAM_CHAT_ID`        | `-1001234567890`                 |

## Struktur File
```
.
├── config/
│   ├── nginx/jellyfin.conf
│   ├── jellyfin/config.json
│   ├── sonarr/config.xml
│   ├── radarr/config.xml
│   └── supervisord.conf
├── scripts/
│   ├── start.sh
│   └── send_keys.py
├── Dockerfile
└── fly.toml
```

## Deployment
1. Clone repository:
```bash
git clone https://github.com/rbbaprianto/nonton.git
cd nonton
```

2. Push ke Fly.io:
```bash
git push origin main
```

Proses otomatis akan:
1. Build Docker image
2. Generate API keys terenkripsi
3. Konfigurasi reverse proxy
4. Kirim notifikasi ke Telegram

## Manajemen

### Perintah Fly.io
```bash
# Masuk ke container
flyctl ssh console -a nonton

# Lihat logs
flyctl logs -a nonton

# Scale resources
flyctl scale memory 2048 -a nonton
```

### Environment Variables
| Variable               | Contoh Value               |
|------------------------|----------------------------|
| `JELLYFIN_API_KEY`     | `d3b07384d113edec49...`    |
| `RADARR_API_KEY`       | `c157a79031e1c40f...`      |
| `ENCRYPTION_PASSWORD`  | `aes256-encrypted-secret`  |

## Keamanan
- API keys dienkripsi dengan AES-256
- Notifikasi Telegram untuk aktivitas kritis
- Tailscale VPN untuk akses internal
- Auto-healing dengan Supervisord

## Lisensi
MIT License
```