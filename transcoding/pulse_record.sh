#!/bin/bash

ffmpeg -y \
-f pulse -i MySink.monitor \
-f pulse -i MySink2.monitor \
-map 0:a video.mp4 \
-map 0:a:0 audio_1.mp3 \
-map 1:a:0 audio_2.wav
