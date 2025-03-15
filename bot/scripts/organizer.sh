#!/bin/sh
# Pindahkan file selesai ke library
find /downloads -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -exec mv {} /library/movies/ \;

# Hapus file sampah
find /downloads -type f \( -name "*.txt" -o -name "*.nfo" \) -delete

# Update permission
chmod -R 755 /library
