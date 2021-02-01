#!/bin/bash

ffmpeg -y -video_size 1920x1080 -framerate 60 \
    -f x11grab -i :0.0 \
    -f pulse -i MySink.monitor \
    -f pulse -i MySink2.monitor \
    -filter_complex \
    "[1:a][2:a]amerge=inputs=2[a];[1:a][2:a]amerge=inputs=2[b]"\
    -map 0 0.mkv\
    -map 1 -ac 1 1.mp3 \
    -map 2 -ac 1 2.mp3 \
    -map "[b]" -ac 1 b.mp3 \
    -map 0 -map "[a]" full.mkv\