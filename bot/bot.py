import os
import logging
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes
from qbittorrent import Client
import yt_dlp as youtube_dl

# Setup
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)
logger = logging.getLogger(__name__)

qb = Client(os.getenv('QB_URL'))
qb.login(os.getenv('QB_USER'), os.getenv('QB_PASS'))

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text('🎬 Media Server Controller Ready!')

async def download(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    if user.id != int(os.getenv('ADMIN_ID')):
        await update.message.reply_text('🚫 Unauthorized!')
        return
    
    url = context.args[0]
    try:
        if url.startswith('magnet:'):
            qb.download_from_link(url)
            msg = '⏳ Torrent added!'
        else:
            ydl_opts = {'outtmpl': '/downloads/%(title)s.%(ext)s'}
            with youtube_dl.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            msg = '📥 Direct download started!'
        
        await update.message.reply_text(msg)
        os.system('/app/scripts/organizer.sh')
        os.system('/app/scripts/subtitle.sh')
    except Exception as e:
        await update.message.reply_text(f'❌ Error: {str(e)}')

if __name__ == '__main__':
    app = Application.builder().token(os.getenv('BOT_TOKEN')).build()
    app.add_handler(CommandHandler('start', start))
    app.add_handler(CommandHandler('download', download))
    app.run_polling()
