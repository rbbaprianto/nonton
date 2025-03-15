#!/bin/bash
find /library -type f \( -name "*.mkv" -o -name "*.mp4" \) -exec subliminal download -l en {} \;
