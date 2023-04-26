#!/bin/bash

export DISPLAY=:0.0
#export GST_DEBUG=*:5
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/gstreamer-1.0

echo "Start RKAIQ Camera Preview!"

ID=$1

gst-launch-1.0 v4l2src device=/dev/video${ID} ! video/x-raw,format=NV12,width=1920,height=1080, framerate=30/1 ! xvimagesink

