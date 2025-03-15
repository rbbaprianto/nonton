import os
import time
import logging
from pathlib import Path

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def cleanup_old_files(days: int = 7):
    try:
        media_path = Path('/media')
        now = time.time()
        
        for f in media_path.rglob('*'):
            if f.is_file() and (now - f.stat().st_mtime) > (days * 86400):
                f.unlink()
                logger.info(f"Deleted: {f}")
                
        return True
    except Exception as e:
        logger.error(f"Cleanup error: {str(e)}")
        return False

if __name__ == "__main__":
    import sys
    days = int(sys.argv[1]) if len(sys.argv) > 1 else 7
    cleanup_old_files(days)
