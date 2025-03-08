import os
import sys
import subprocess
from telegram import Bot, InputFile
from telegram.constants import ParseMode

def send_keys(password):
    try:
        # Decrypt file
        subprocess.run(
            f"openssl enc -d -aes-256-cbc -salt -pass pass:{password} -in /tmp/api_keys.enc -out /tmp/api_keys.txt",
            shell=True,
            check=True
        )
        
        # Read keys
        with open("/tmp/api_keys.txt") as f:
            keys = f.read()
        
        # Init bot
        bot = Bot(token=os.getenv('TELEGRAM_BOT_TOKEN'))
        
        # Send password
        bot.send_message(
            chat_id=os.getenv('TELEGRAM_CHAT_ID'),
            text=f"🔐 *ENCRYPTION PASSWORD* 🔐\n||{password}||",
            parse_mode=ParseMode.MARKDOWN_V2
        )
        
        # Send keys
        bot.send_message(
            chat_id=os.getenv('TELEGRAM_CHAT_ID'),
            text=f"🔑 *API KEYS* 🔑\n```\n{keys}\n```",
            parse_mode=ParseMode.MARKDOWN
        )
        
        # Send encrypted file
        with open("/tmp/api_keys.enc", "rb") as f:
            bot.send_document(
                chat_id=os.getenv('TELEGRAM_CHAT_ID'),
                document=InputFile(f, filename="nonton_keys.enc"),
                caption="🔒 Encrypted API Keys"
            )
            
    except Exception as e:
        print(f"Error: {str(e)}")
    finally:
        # Cleanup
        subprocess.run("rm -f /tmp/api_keys.*", shell=True)

if __name__ == "__main__":
    send_keys(sys.argv[1])