import os
import subprocess
from telegram import Update, Bot
from telegram.ext import Application, CommandHandler, MessageHandler, filters

# Command Handlers
async def status(update: Update, _):
    result = subprocess.run(["flyctl", "status", "-a", "nonton"], capture_output=True)
    await update.message.reply_text(f"`{result.stdout.decode()}`", parse_mode="Markdown")

async def disk_usage(update: Update, _):
    result = subprocess.run(["df", "-h", "/film"], capture_output=True)
    await update.message.reply_text(f"`{result.stdout.decode()}`", parse_mode="Markdown")

async def extend_storage(update: Update, context):
    size = context.args[0]
    chat_id = update.message.chat.id
    if int(size) < 10:
        await update.message.reply_text("❌ Minimum extension is 10GB")
        return
    
    # Trigger GitHub Action
    subprocess.run([
        "gh", "workflow", "run", "volume.yml",
        "-f", f"action=extend",
        "-f", f"size={size}"
    ])
    
    await update.message.reply_text(f"✅ Extending storage by {size}GB...")

def main():
    app = Application.builder().token(os.getenv('TELEGRAM_BOT_TOKEN')).build()
    
    app.add_handler(CommandHandler("status", status))
    app.add_handler(CommandHandler("disk", disk_usage))
    app.add_handler(CommandHandler("extend_storage", extend_storage))
    
    app.run_polling()

if __name__ == "__main__":
    main()