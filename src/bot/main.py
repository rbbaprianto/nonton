import os
import logging
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes
from qbittorrent import Client

# Initialize logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

qb = Client("http://qbittorrent:8080")

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🤖 Media Server Controller\n\n"
        "Available commands:\n"
        "/download [magnet_url]\n"
        "/status\n"
        "/library\n"
        "/cleanup [days]"
    )

async def download(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        magnet = ' '.join(context.args)
        if not magnet.startswith('magnet:'):
            raise ValueError("Invalid magnet link")
            
        qb.login(os.getenv('QB_USER'), os.getenv('QB_PASS'))
        qb.download_from_link(magnet)
        
        await update.message.reply_text(f"✅ Added: {magnet[:60]}...")
    except Exception as e:
        logger.error(f"Download error: {str(e)}")
        await update.message.reply_text("❌ Failed to add torrent")

async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        qb.login(os.getenv('QB_USER'), os.getenv('QB_PASS'))
        torrents = qb.torrents()
        
        if not torrents:
            await update.message.reply_text("📭 No active downloads")
            return
            
        response = ["📥 Current Downloads:"]
        for torrent in torrents:
            progress = torrent['progress'] * 100
            response.append(
                f"\n📛 {torrent['name']}\n"
                f"📊 {progress:.1f}% | "
                f"⬇️ {torrent['dlspeed']/1024:.1f} KB/s"
            )
            
        await update.message.reply_text('\n'.join(response))
    except Exception as e:
        logger.error(f"Status error: {str(e)}")
        await update.message.reply_text("❌ Failed to get status")

if __name__ == '__main__':
    app = Application.builder().token(os.getenv('TELEGRAM_TOKEN')).build()
    
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("download", download))
    app.add_handler(CommandHandler("status", status))
    
    app.run_polling()
