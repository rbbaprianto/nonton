import os
import subprocess
import logging
from telegram import Update, Bot
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

# Setup logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Command Handlers
async def status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        logger.info(f"Status command received from {update.effective_user.id}")
        result = subprocess.run(
            ["flyctl", "status", "-a", "nonton"],
            capture_output=True,
            text=True,
            timeout=15
        )
        output = result.stdout if result.stdout else result.stderr
        await update.message.reply_text(f"```\n{output}\n```", parse_mode="MarkdownV2")
    except Exception as e:
        logger.error(f"Status error: {str(e)}")
        await update.message.reply_text(f"⚠️ Error: {str(e)}")

async def disk_usage(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        logger.info(f"Disk command received from {update.effective_user.id}")
        result = subprocess.run(
            ["df", "-h", "/film"],
            capture_output=True,
            text=True,
            timeout=10
        )
        output = result.stdout if result.stdout else result.stderr
        await update.message.reply_text(f"```\n{output}\n```", parse_mode="MarkdownV2")
    except Exception as e:
        logger.error(f"Disk error: {str(e)}")
        await update.message.reply_text(f"⚠️ Error: {str(e)}")

async def extend_storage(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        user = update.effective_user
        logger.info(f"Extend command from {user.id} ({user.username})")
        
        if not context.args:
            raise ValueError("Missing size parameter")
            
        size = int(context.args[0])
        
        if size < 10:
            await update.message.reply_text("❌ Minimum extension is 10GB")
            return
        if size > 100:
            await update.message.reply_text("❌ Maximum extension is 100GB")
            return

        # Trigger GitHub Action
        process = subprocess.run(
            [
                "gh", "workflow", "run", "volume.yml",
                "-f", f"action=extend",
                "-f", f"size={size}"
            ],
            capture_output=True,
            text=True,
            timeout=20
        )
        
        if process.returncode != 0:
            raise RuntimeError(process.stderr)
            
        await update.message.reply_text(f"✅ Extending storage by {size}GB...")
        
    except Exception as e:
        logger.error(f"Extend error: {str(e)}")
        await update.message.reply_text(f"⚠️ Error: {str(e)}\nUsage: /extend_storage <size_gb>")

async def error_handler(update: object, context: ContextTypes.DEFAULT_TYPE):
    logger.error(f"Exception while handling update: {context.error}")
    if isinstance(update, Update):
        await update.message.reply_text(f"🔥 Critical Error: {context.error}")

def main():
    # Initialize bot
    bot = Bot(token=os.getenv('TELEGRAM_BOT_TOKEN'))
    app = Application.builder().token(os.getenv('TELEGRAM_BOT_TOKEN')).build()
    
    # Add handlers
    app.add_handler(CommandHandler("status", status))
    app.add_handler(CommandHandler("disk", disk_usage))
    app.add_handler(CommandHandler("extend_storage", extend_storage))
    app.add_error_handler(error_handler)

    # Webhook configuration for Fly.io
    if os.getenv('FLY_APP_NAME'):
        url = f"https://{os.getenv('FLY_APP_NAME')}.fly.dev/"
        port = int(os.getenv('PORT', 8080))
        
        app.run_webhook(
            listen='0.0.0.0',
            port=port,
            webhook_url=url,
            secret_token=os.getenv('WEBHOOK_SECRET'),
        )
    else:
        # Local development with polling
        app.run_polling()

if __name__ == "__main__":
    main()
