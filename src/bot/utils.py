import requests
import logging

logger = logging.getLogger(__name__)

def jellyfin_library(api_key: str):
    try:
        response = requests.get(
            "http://jellyfin:8096/Items",
            headers={"X-Emby-Token": api_key}
        )
        response.raise_for_status()
        return response.json()['Items']
    except Exception as e:
        logger.error(f"Jellyfin error: {str(e)}")
        return None

def handle_qb_error(e: Exception):
    logger.error(f"qBittorrent API Error: {str(e)}")
    return "⚠️ Server connection error"
