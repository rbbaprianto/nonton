import os
import logging
from subliminal import download_best_subtitles, scan_videos
from babelfish import Language

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def download_subs():
    try:
        videos = scan_videos('/media', age=60)
        subs = download_best_subtitles(
            videos,
            {Language('eng')},
            providers=['opensubtitles'],
            provider_configs={
                'opensubtitles': {
                    'username': os.getenv('OPENSUBTITLES_USER'),
                    'password': os.getenv('OPENSUBTITLES_PASS')
                }
            }
        )
        for video in videos:
            if video.subtitle:
                video.subtitle.save()
                logger.info(f"Saved subs for {video.name}")
    except Exception as e:
        logger.error(f"Sub error: {str(e)}")

if __name__ == "__main__":
    download_subs()
