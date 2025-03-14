#!/bin/sh
# Pindahkan file yang selesai didownload ke library
find /downloads -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" \) -exec mv {} /media/movies/ \;
