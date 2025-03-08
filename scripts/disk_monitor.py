# scripts/disk_monitor.py

import shutil
import os
import requests

def check_disk():
    usage = shutil.disk_usage("/film")
    return (usage.used / usage.total) * 100

def send_alert(level, message):
    bot_token = os.getenv('TELEGRAM_BOT_TOKEN')
    chat_id = os.getenv('TELEGRAM_CHAT_ID')
    
    emoji = "🟢" if level == "info" else "🟠" if level == "warning" else "🔴"
    
    requests.post(
        f"https://api.telegram.org/bot{bot_token}/sendMessage",
        json={
            "chat_id": chat_id,
            "text": f"{emoji} *Disk Monitor* {emoji}\n{message}",
            "parse_mode": "Markdown"
        }
    )

if __name__ == "__main__":
    usage = check_disk()
    
    if usage > 95:
        send_alert("critical", f"""
💾 *CRITICAL STORAGE*
Path: /film
Usage: {usage:.2f}%

🚨 Immediate action required!
Run: /extend_storage [GB]
        """)
    elif usage > 80:
        send_alert("warning", f"""
💾 *High Storage Usage*
Path: /film
Usage: {usage:.2f}%

⚠️ Consider extending storage soon
        """)