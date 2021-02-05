#!/bin/bash

set -xeo pipefail

BROWSER_URL=${MEETING_URL}
SCREEN_WIDTH=720
SCREEN_HEIGHT=480
SCREEN_RESOLUTION=${SCREEN_WIDTH}x${SCREEN_HEIGHT}
COLOR_DEPTH=24
X_SERVER_NUM=2
VIDEO_BITRATE=3000
VIDEO_FRAMERATE=30
VIDEO_GOP=$((VIDEO_FRAMERATE * 2))
AUDIO_BITRATE=160k
AUDIO_SAMPLERATE=44100
AUDIO_CHANNELS=1

RTMP_URL1=rtmps://29d142160793.global-contribute.live-video.net:443/app/sk_eu-west-1_O1mpPZ4vn8y7_adz7ekds4hoQlhZRoKDpL3XLyqzYRy
RTMP_URL2=rtmps://29d142160793.global-contribute.live-video.net:443/app/sk_eu-west-1_ut1Ov5JhB4PM_VndsUAMG1Kq0Dy3OWaR8UXKi6vd7Qg
RTMP_URL3=rtmps://29d142160793.global-contribute.live-video.net:443/app/sk_eu-west-1_7CBJ18csCjci_YZxNW28tXViemH4sZl7RymYoy3PQUz
RTMP_URL4=rtmps://29d142160793.global-contribute.live-video.net:443/app/sk_eu-west-1_yjG2UVbNBqrT_DXOmduEA5JFUgD1Zbxp5l1S9eAGkka
#BROWSER_URL=https://dealroom-html.s3-eu-west-1.amazonaws.com/sink.html

pkill pulse || echo "pulse was not running"
pkill firefox || echo "firefox was not running"
sleep 1
# Start PulseAudio server so Firefox will have somewhere to which to send audio
pulseaudio -D --exit-idle-time=-1
#pacmd load-module module-virtual-sink sink_name=v1  # Load a virtual sink as `v1`
#pacmd set-default-sink v1  # Set the `v1` as the default sink device
#pacmd set-default-source v1.monitor  # Set the monitor of the v1 sink to be the default source

if pactl list short sources | grep MySink; 
then
   echo "exist"
else
  echo "not exist"
  pacmd load-module module-null-sink sink_name=MySink
  pacmd update-sink-proplist MySink device.description=MySink
  pacmd load-module module-null-sink sink_name=MySink2
  pacmd update-sink-proplist MySink2 device.description=MySink2

  pacmd load-module module-null-sink sink_name=MySink3
  pacmd update-sink-proplist MySink3 device.description=MySink3
  pacmd load-module module-null-sink sink_name=MySink4
  pacmd update-sink-proplist MySink4 device.description=MySink4
fi



# Start X11 virtual framebuffer so Firefox will have somewhere to draw
Xvfb :${X_SERVER_NUM} -ac -screen 0 ${SCREEN_RESOLUTION}x${COLOR_DEPTH} > /dev/null 2>&1 &
export DISPLAY=:${X_SERVER_NUM}.0
sleep 0.5  # Ensure this has started before moving on

# Create a new Firefox profile for capturing preferences for this
firefox --no-remote --new-instance --createprofile "foo7 /tmp/foo7"

# Install the OpenH264 plugin for Firefox
mkdir -p /tmp/foo7/gmp-gmpopenh264/1.8.1.1/
pushd /tmp/foo7/gmp-gmpopenh264/1.8.1.1 >& /dev/null
curl -s -O http://ciscobinary.openh264.org/openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
unzip -n openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
rm -f openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip
popd >& /dev/null

# Set the Firefox preferences to enable automatic media playing with no user
# interaction and the use of the OpenH264 plugin.
cat <<EOF >> /tmp/foo7/prefs.js
user_pref("media.autoplay.default", 0);
user_pref("media.autoplay.enabled.user-gestures-needed", false);
user_pref("media.navigator.permission.disabled", true);
user_pref("media.gmp-gmpopenh264.abi", "x86_64-gcc3");
user_pref("media.gmp-gmpopenh264.lastUpdate", 1571534329);
user_pref("media.gmp-gmpopenh264.version", "1.8.1.1");
user_pref("doh-rollout.doorhanger-shown", true);
user_pref("media.setsinkid.enabled", true);
user_pref("browser.cache.disk.enable", false);
EOF

# Start Firefox browser and point it at the URL we want to capture
#
# NB: The `--width` and `--height` arguments have to be very early in the
# argument list or else only a white screen will result in the capture for some
# reason.
firefox \
  -P foo7 \
  --width ${SCREEN_WIDTH} \
  --height ${SCREEN_HEIGHT} \
  --new-instance \
  --first-startup \
  --foreground \
  --kiosk \
  --ssb \
  "${BROWSER_URL}" \
  &
sleep 0.5  # Ensure this has started before moving on
xdotool mousemove 1 1 click 1  # Move mouse out of the way so it doesn't trigger the "pause" overlay on the video tile

# Start ffmpeg to transcode the capture from the X11 framebuffer and the
# PulseAudio virtual sound device we created earlier and send that to the RTMP
# endpoint in H.264/AAC format using a FLV container format.
#
# NB: These arguments have a very specific order. Seemingly inocuous changes in
# argument order can have pretty drastic effects, so be careful when
# adding/removing/reordering arguments here.
ffmpeg -y\
  -hide_banner -loglevel error \
  -nostdin \
  -s ${SCREEN_RESOLUTION} \
  -r ${VIDEO_FRAMERATE} \
  -draw_mouse 0 \
  -f x11grab \
    -i ${DISPLAY} \
  -f pulse -i MySink.monitor \
  -f pulse -i MySink2.monitor \
  -f pulse -i MySink3.monitor \
  -f pulse -i MySink4.monitor \
  -c:v libx264 \
    -pix_fmt yuv420p \
    -profile:v main \
    -preset veryfast \
    -minrate ${VIDEO_BITRATE} \
    -maxrate ${VIDEO_BITRATE} \
    -g ${VIDEO_GOP} \
    -map 0 -f flv -map 1  ${RTMP_URL1} \
  -c:v libx264 \
    -pix_fmt yuv420p \
    -profile:v main \
    -preset veryfast \
    -minrate ${VIDEO_BITRATE} \
    -maxrate ${VIDEO_BITRATE} \
    -g ${VIDEO_GOP} \
    -map 0 -f flv -map 2  ${RTMP_URL2} \
  -c:v libx264 \
    -pix_fmt yuv420p \
    -profile:v main \
    -preset veryfast \
    -minrate ${VIDEO_BITRATE} \
    -maxrate ${VIDEO_BITRATE} \
    -g ${VIDEO_GOP} \
    -map 0 -f flv -map 3  ${RTMP_URL3} \
  -c:v libx264 \
    -pix_fmt yuv420p \
    -profile:v main \
    -preset veryfast \
    -minrate ${VIDEO_BITRATE} \
    -maxrate ${VIDEO_BITRATE} \
    -g ${VIDEO_GOP} \
    -map 0 -f flv -map 4  ${RTMP_URL4} \
  
      

