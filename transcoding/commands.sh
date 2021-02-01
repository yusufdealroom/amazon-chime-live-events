pactl list
aplay -l
pulseaudio -k
pulseaudio --start

ffmpeg -i video.flv -f mp4 -movflags frag_keyframe+empty_moov pipe:1 | aws s3 cp - s3://dealroomvideos/deneme.flv

ffprobe -show_entries stream=channels,channel_layout -of compact=p=0:nk=1 -v 0 - <(ffmpeg -i LFE-SBR.mp4 -f matroska -) 2> /dev/null

ffmpeg -i LFE-SBR.mp4 -f matroska - |  ffprobe -show_entries stream=channels -of compact=p=0:nk=1 -v 0 -

ls -la $(which firefox)

-filter_complex 'channelsplit=channel_layout=5.1[FL][FR][FC][LFE][SL][SR]' -map '[FL]' front_left2.wav -map '[FR]' front_right2.wav -map '[FC]' front_center2.wav -map '[LFE]' lfe2.wav -map '[SL]' side_left2.wav -map '[SR]' side_right2.wav

-map_channel 0.0.0 OUTPUT_CH0.flv -map_channel 0.0.1 OUTPUT_CH1.flv


ilk videoda video ve ses var. ikincide sadece ses var. outputa ilk videnun 0.cı streamini ve 2 videonun audio 0 larını gönderir. 
ffmpeg -i ChID-BLITS-EBU.mp4 -i SBRtestStereoAot5Sig1.mp4 -c:v copy -c:a aac -map 0:v:0 -map 0:a:0 -map 1:a:0 output.mp4

ffprobe output.mp4 ile bakınca içinde 1 video ve 2 audio olduğu görünür. 



ffmpeg -i ChID-BLITS-EBU.mp4 -i OUTPUT_CH0.flv -i OUTPUT_CH1.flv -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 -map 2:a:0 output2.mp4