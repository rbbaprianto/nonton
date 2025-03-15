import os
import logging
import requests
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes
from qbittorrent import Client
import yt_dlp as youtube_dl
from subprocess import check_output

# Config
QB_URL = os.getenv('QB_URL', 'http://qbittorrent:8080')
LIBRARY_PATH = os.getenv('LIBRARY_PATH', '/library')
ADMIN_ID = int(os.getenv('ADMIN_ID', '1234567890'))

# Setup
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

qb = Client(QB_URL)
qb.login(os.getenv('QB_USER'), os.getenv('QB_PASS'))

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🎬 **Media Server Controller**\n\n"
        "Available commands:\n"
        "/download [url/magnet] - Start download\n"
        "/status - Server status\n"
        "/library - List media\n"
        "/cleanup - Delete completed files"
    )

async def download(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    if user.id != ADMIN_ID:
        await update.message.reply_text("❌ Unauthorized!")
        return
    
    if not context.args:
        await update.message.reply_text("⚠️ Please provide URL/magnet!")
        return
    
    url = ' '.join(context.args)
    try:
        if url.startswith('magnet:'):
            qb.download_from_link(url)
            msg = "⏳ Torrent added to queue!"
        else:
            ydl_opts = {'outtmpl': '/downloads/%(title)s.%(ext)s'}
            with youtube_dl.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            msg = "📥 Direct download started!"
        
        await update.message.reply_text(msg)
        check_output(["/app/scripts/organizer.sh"])
        check_output(["/app/scripts/subtitle.sh"])
    except Exception as e:
        await update.message.reply_text(f"🔥 Error: {str(e)}")

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        # qBittorrent status
        torrents = qb.torrents()
        active = sum(1 for t in torrents if t['state'] in ['downloading', 'uploading'])
        
        # System status
        disk = check_output(["df", "-h", "/downloads"]).decode().split('\n')[1]
        
        status_msg = (
            f"🖥 **Server Status**\n"
            f"• Active Torrents: {active}/{len(torrents)}\n"
            f"• Disk Usage: {disk.split()[3]} free\n"
            f"• Jellyfin: {'🟢 Online' if os.system('ping -c 1 jellyfin') == 0 else '🔴 Offline'}"
        )
        await update.message.reply_text(status_msg)
    except Exception as e:
        await update.message.reply_text(f"❌ Status error: {str(e)}")

async def list_library(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        files = check_output(["find", LIBRARY_PATH, "-type", "f"]).decode().split('\n')
        file_list = "\n".join([f"• {os.path.basename(f)}" for f in files[:10] if f])
        await update.message.reply_text(f"📂 **Library Contents**\n{file_list}")
    except Exception as e:
        await update.message.reply_text(f"❌ Library error: {str(e)}")

async def cleanup(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        check_output(["find", "/downloads", "-type", "f", "-delete"])
        await update.message.reply_text("🧹 Cleanup completed!")
    except Exception as e:
        await update.message.reply_text(f"❌ Cleanup failed: {str(e)}")

def main():
    app = Application.builder().token(os.getenv('BOT_TOKEN')).build()
    
    handlers = [
        CommandHandler('start', start),
        CommandHandler('download', download),
        CommandHandler('status', status),
        CommandHandler('library', list_library),
        CommandHandler('cleanup', cleanup)
    ]
    
    for handler in handlers:
        app.add_handler(handler)
    
    app.run_polling()

if __name
