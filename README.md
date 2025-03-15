# 🎬 Nonton - All-in-One Media Server Platform

![Deployment Status](https://img.shields.io/github/actions/workflow/status/rbbaprianto/nonton/deploy.yml?branch=main&label=Deployment)
![Fly.io](https://img.shields.io/badge/Fly.io-Deployed-8A2BE2)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED)
![License](https://img.shields.io/badge/License-MIT-brightgreen)

**Nonton** adalah platform media server lengkap untuk streaming, manajemen konten, dan otomasi unduhan.  
Dibangun menggunakan **Docker** dan dideploy ke **Fly.io** dengan sistem keamanan yang solid.

🔗 **Demo Live**: [nonton.fly.dev](https://nonton.fly.dev) *(akses terbatas)**

## 🚀 Cara Deploy

### 🧰 Prasyarat
✅ Akun [Fly.io](https://fly.io) dengan token API  
✅ Akun [Tailscale](https://tailscale.com) dengan auth key  
✅ Bot Telegram dari [@BotFather](https://t.me/BotFather)  

### ⚙️ Langkah 1 - Setup GitHub Secrets
Buka repo Anda → **Settings → Secrets and variables → Actions**  
Tambahkan data berikut:

- `FLY_API_TOKEN` → Token Fly.io (dapatkan via `flyctl auth token`)  
- `TAILSCALE_AUTHKEY` → Auth key Tailscale  
- `TELEGRAM_BOT_TOKEN` → Token bot Telegram  
- `TELEGRAM_CHAT_ID` → ID chat Telegram Anda  
- `ENCRYPTION_PASSWORD` → Kosongkan (akan di-generate otomatis)  

### 🚢 Langkah 2 - Deploy ke Fly.io
```bash
git clone https://github.com/rbbaprianto/nonton.git
cd nonton
git push origin main
```

Proses otomatis akan:  
✅ Membuat aplikasi di Fly.io  
✅ Build Docker image  
✅ Generate API keys & enkripsi  
✅ Kirim notifikasi ke Telegram  

## 🔧 Konfigurasi Lanjutan

### 📂 Struktur File
```bash
.
├── config/
│   ├── nginx/            # Reverse proxy config
│   ├── jellyfin/         # Jellyfin config + SSL
│   ├── sonarr/           # Sonarr config
│   ├── radarr/           # Radarr config
│   └── supervisord.conf  # Process manager
├── scripts/
│   ├── start.sh          # Init script
│   └── send_keys.py      # Telegram notifier
└── fly.toml              # Fly.io config
```

### 🌐 Custom Domain
1. Tambahkan domain di Fly.io:
```bash
flyctl certs add yourdomain.com
```
2. Update `config/nginx/jellyfin.conf`:
```nginx
server_name yourdomain.com;
```

## 🛠️ Manajemen Layanan

### Perintah Dasar
```bash
# Masuk ke container
flyctl ssh console -a nonton

# Restart service
flyctl apps restart nonton

# Scale resources
flyctl scale memory 2048 -a nonton
```

### Monitoring
```bash
# Lihat logs real-time
flyctl logs -a nonton

# Cek status aplikasi
flyctl status -a nonton

# Monitoring resource
flyctl monitor -a nonton
```

## 🔒 Keamanan

### 🔐 Enkripsi Data
- **API Keys** dihasilkan otomatis saat deploy pertama  
- Dienkripsi dengan **AES-256-CBC**  
- Dikirim via Telegram sebagai file `.enc`  

### ⚠️ Best Practices
1. Rotate API keys tiap 90 hari:
```bash
flyctl secrets set JELLYFIN_API_KEY=$(uuidgen) -a nonton
```
2. Update password secara berkala:
```bash
flyctl secrets set QBITTORRENT_WEBUI_PASSWORD="password_baru" -a nonton
```

## 🚨 Troubleshooting

**Deployment Gagal**  
✅ Pastikan semua secrets sudah terisi  
✅ Cek kuota Fly.io  
✅ Verifikasi Dockerfile bisa build secara lokal  

**Service Tidak Muncul**  
✅ Cek logs via `flyctl logs`  
✅ Verifikasi port mapping di `fly.toml`  
✅ Pastikan resource cukup (minimal 1GB RAM)  

**Notifikasi Telegram Tidak Masuk**  
✅ Verifikasi token bot  
✅ Pastikan chat ID benar  
✅ Cek firewall blocking Telegram API  

## 🤝 Kontribusi

Terbuka untuk issue dan pull request!  
Lihat [CONTRIBUTING.md](.github/CONTRIBUTING.md) untuk panduan lengkap.

## 📜 Lisensi
Proyek ini menggunakan lisensi [MIT](LICENSE).
