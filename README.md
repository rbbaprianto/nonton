# 🎬 Nonton - All-in-One Media Server Platform

![Deployment Status](https://img.shields.io/github/actions/workflow/status/rbbaprianto/nonton/deploy.yml?branch=develop&label=Deployment)
![Fly.io](https://img.shields.io/badge/Fly.io-Deployed-8A2BE2)
![Docker](https://img.shields.io/badge/Docker-Containerized-2496ED)
![License](https://img.shields.io/badge/License-MIT-brightgreen)

## 📂 Struktur File
```bash
media-server/
├── docker-compose.yml
├── .env.prod
├── bot/
│   ├── Dockerfile
│   ├── bot.py
│   ├── requirements.txt
│   └── scripts/
│       ├── subtitle.sh
│       └── organizer.sh
├── config/
│   ├── qbittorrent/
│   └── jellyfin/
└── .github/
    └── workflows/
        └── deploy.yml
```

## 📜 Lisensi
Proyek ini menggunakan lisensi [MIT](LICENSE).
