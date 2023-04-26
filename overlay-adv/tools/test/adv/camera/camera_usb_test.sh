#!/bin/bash

export DISPLAY=:0.0
#export GST_DEBUG=*:5
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/gstreamer-1.0


echo "Start UVC Camera M-JPEG Preview!"

ID=$1

gst-launch-1.0 v4l2src device=/dev/video${ID} ! image/jpeg, width=1280, height=720, framerate=30/1 ! jpegparse ! mppjpegdec ! xvimagesink sync=false


