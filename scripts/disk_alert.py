import shutil
import os
import requests

def check_disk():
    usage = shutil.disk_usage("/film")
    percent = (usage.used / usage.total) * 100
    return percent

def send_telegram_alert(message):
    bot_token = os.getenv('TELEGRAM_BOT_TOKEN')
    chat_id = os.getenv('TELEGRAM_CHAT_ID')
    requests.post(
        f"https://api.telegram.org/bot{bot_token}/sendMessage",
        json={
            "chat_id": chat_id,
            "text": f"🚨 *Disk Alert* 🚨\n{message}",
            "parse_mode": "Markdown"
        }
    )

if __name__ == "__main__":
    usage = check_disk()
    if usage > 95:
        send_telegram_alert(f"""
💾 Disk Usage Critical!
Path: /film
Usage: {usage:.2f}%

⚠️ Please extend storage with:
`/extend_storage 15`
""")