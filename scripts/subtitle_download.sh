#!/bin/sh
find /media -type f \( -name "*.mkv" -o -name "*.mp4" \) -print0 | while IFS= read -r -d '' file; do
    subliminal download -l en "$file"
done
