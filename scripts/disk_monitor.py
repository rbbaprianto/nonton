#!/usr/bin/env python3
import os
import requests
import shutil
import time

TELEGRAM_TOKEN = os.getenv('TELEGRAM_TOKEN')
TELEGRAM_CHAT_ID = os.getenv('TELEGRAM_CHAT_ID')
VOLUME_NAME = 'media_volume'
THRESHOLD = 90
MIN_EXTEND_GB = 5

def send_alert(message):
    try:
        requests.post(
            f'https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage',
            json={'chat_id': TELEGRAM_CHAT_ID, 'text': message, 'parse_mode': 'Markdown'}
        )
    except Exception as e:
        print(f"Alert failed: {str(e)}")

def check_disk():
    total, used, _ = shutil.disk_usage("/media")
    return (used / total) * 100

def extend_volume():
    current_size = int(os.popen(f'fly volumes list -a nonton | grep {VOLUME_NAME} | awk \'{{print $3}}\'').read().strip())
    new_size = current_size + MIN_EXTEND_GB
    exit_code = os.system(f'fly volumes extend {VOLUME_NAME} -a nonton -s {new_size} > /dev/null 2>&1')
    return new_size if exit_code == 0 else None

def main():
    while True:
        try:
            usage = check_disk()
            if usage >= THRESHOLD:
                new_size = extend_volume()
                if new_size:
                    msg = f"🚨 **Disk Alert**\n\n• Usage: {usage:.1f}%\n• New Size: {new_size}GB\n• App: [nonton.fly.dev](https://nonton.fly.dev)"
                    send_alert(msg)
            time.sleep(300)
        except Exception as e:
            print(f"Error: {str(e)}")
            time.sleep(60)

if __name__ == "__main__":
    main()