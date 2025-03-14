import os
import logging
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes
from qbittorrent import Client
import yt_dlp as youtube_dl
from subliminal import download_best_subtitles, scan_videos

# Config
QB_URL = os.getenv('QBITTORRENT_URL', 'http://qbittorrent:8080')
LIBRARY_PATH = os.getenv('LIBRARY_PATH', '/media')
TG_ADMIN_ID = int(os.getenv('TG_ADMIN_ID', '123456789'))

# Setup logging
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

qb = Client(QB_URL)
qb.login('admin', 'adminadmin')  # Ganti dengan credentials yang lebih aman

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text('🚀 Media Server Controller Ready!')

async def handle_download(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if update.effective_user.id != TG_ADMIN_ID:
        await update.message.reply_text('❌ Unauthorized!')
        return
    
    url = ' '.join(context.args)
    if not url:
        await update.message.reply_text('⚠️ Please provide URL/magnet!')
        return
    
    try:
        if url.startswith('magnet:'):
            qb.download_from_link(url)
            msg = '⏳ Torrent added to queue!'
        else:
            ydl_opts = {'outtmpl': '/downloads/%(title)s.%(ext)s'}
            with youtube_dl.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            msg = '⏳ Direct download started!'
        
        await update.message.reply_text(msg)
        os.system('/scripts/organize_files.sh')
        os.system('/scripts/subtitle_download.sh')
    except Exception as e:
        await update.message.reply_text(f'❌ Error: {str(e)}')

async def server_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    status = {
        'Torrents Active': len(qb.torrents()),
        'Free Space': f"{round(os.statvfs('/downloads').f_bfree/1024/1024)}GB",
        'Jellyfin Status': 'Online' if os.system('ping -c 1 jellyfin') == 0 else 'Offline'
    }
    await update.message.reply_text('\n'.join([f'{k}: {v}' for k,v in status.items()]))

def main():
    app = Application.builder().token(os.getenv('BOT_TOKEN')).build()
    
    app.add_handler(CommandHandler('start', start))
    app.add_handler(CommandHandler('download', handle_download))
    app.add_handler(CommandHandler('status', server_status))
    
    app.run_polling()

if __name__ == '__main__':
    main()
