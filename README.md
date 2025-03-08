```markdown
# 🎬 Nonton - Media Server Suite

![GitHub Actions](https://github.com/rbbaprianto/nonton/workflows/Deploy%20Nonton/badge.svg)
![Fly.io Deployment](https://img.shields.io/badge/deployed%20on-fly.io-blue)
![License](https://img.shields.io/badge/license-MIT-green)

All-in-one media server solution dengan integrasi Jellyfin, *Arr stack, dan tools pendukung lainnya. Deploy otomatis ke Fly.io dengan enkripsi API keys dan notifikasi Telegram.

## 🌟 Fitur Utama
- **Streaming Media**: Jellyfin dengan konfigurasi optimal
- **Manajemen Konten**: 
  - Sonarr (Series TV)
  - Radarr (Film)
  - Bazarr (Subtitle)
- **Unduhan**: 
  - qBittorrent
  - Aria2
- **Monitoring**: 
  - Uptime Kuma
  - Netdata
- **Keamanan**:
  - Tailscale VPN
  - Enkripsi API keys AES-256
- **Otomasi**:
  - Auto-deploy dengan GitHub Actions
  - Notifikasi Telegram
  - Self-healing dengan Supervisord

## 🚀 Instalasi

### Prasyarat
- Akun [Fly.io](https://fly.io)
- Akun [Tailscale](https://tailscale.com)
- Bot Telegram (@BotFather)

### Langkah Deploy
1. **Clone Repository**
```bash
git clone https://github.com/rbbaprianto/nonton.git
cd nonton
```

2. **Setup GitHub Secrets**  
Buka repo Settings > Secrets > Actions, tambahkan:
- `FLY_API_TOKEN` - Token Fly.io
- `TAILSCALE_AUTHKEY` - Tailscale auth key
- `TELEGRAM_BOT_TOKEN` - Dari @BotFather
- `TELEGRAM_CHAT_ID` - ID chat Anda
- `ENCRYPTION_PASSWORD` (biarkan kosong untuk auto-generate)

3. **Deploy ke Fly.io**  
Push ke branch `main` untuk trigger deploy otomatis:
```bash
git push origin main
```

## 🔧 Konfigurasi
### Struktur File Penting
```
config/
├── nginx/            # Reverse proxy config
├── jellyfin/         # Konfigurasi Jellyfin
├── *arr/             # Konfigurasi Sonarr/Radarr/Bazarr
└── supervisord.conf  # Manajemen proses
```

### Environment Variables
File `.env.example` akan di-generate otomatis dengan:
```ini
JELLYFIN_API_KEY=auto-generated
TAILSCALE_AUTHKEY=your_tailscale_key
...
```

## 🛠️ Penggunaan
### Akses Layanan
| Service       | URL                          |
|---------------|------------------------------|
| Jellyfin      | `https://nonton.fly.dev`     |
| qBittorrent   | `https://nonton.fly.dev:8080`|
| Sonarr        | `https://nonton.fly.dev/sonarr` |

### Perintah Utama
```bash
# Cek status aplikasi
flyctl status --app nonton

# Buka aplikasi
flyctl open --app nonton

# Lihat logs
flyctl logs --app nonton
```

## 🔒 Keamanan
1. **API Keys**  
   - Auto-generate saat deploy pertama
   - Terenkripsi dengan AES-256
   - Dikirim via Telegram dalam format aman

2. **Jaringan**  
   - Tailscale VPN untuk akses internal
   - SSL otomatis dari Fly.io

## 🤖 Notifikasi Telegram
Contoh notifikasi yang akan diterima:
```
🚀 DEPLOYMENT SUCCESS
App: nonton
URL: https://nonton.fly.dev
API Keys: [terlampir file terenkripsi]
```

## 📂 Struktur Proyek
```bash
.
├── .github/          # Workflow CI/CD
├── config/           # File konfigurasi semua layanan
├── scripts/          # Script deployment & notifikasi
├── Dockerfile        # Konfigurasi Docker
└── fly.toml          # Konfigurasi Fly.io
```

## 🤝 Berkontribusi
1. Fork repository
2. Buat branch fitur (`git checkout -b fitur/namafitur`)
3. Commit perubahan (`git commit -m 'Tambahkan fitur'`)
4. Push ke branch (`git push origin fitur/namafitur`)
5. Buat Pull Request

## 📜 Lisensi
Proyek ini dilisensikan di bawah [MIT License](LICENSE)
```