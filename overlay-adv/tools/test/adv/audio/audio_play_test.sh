#!/bin/bash
# usage :
#        audio_play_test.sh

TEST_ITEM="audio play"
DIR=`dirname $0`
RECORD_FILE="$DIR/test.wav"

ASOUND_CARD=rockchip$1

echo "$TEST_ITEM Testing ..."

CARD_ID=`cat /proc/asound/cards | grep ${ASOUND_CARD} | awk '{printf $1}'`
echo CARD_ID=$CARD_ID

amixer -c $CARD_ID cset numid=1 6
aplay -Dplughw:$CARD_ID,0 -t wav $RECORD_FILE

echo "$TEST_ITEM Test Finish"
