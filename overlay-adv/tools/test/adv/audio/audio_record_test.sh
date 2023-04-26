#!/bin/bash
# usage :
#        audio_record_test.sh

TEST_ITEM="audio record"
DIR=`dirname $0`
RECORD_FILE="$DIR/test.wav"
RECORD_TIME=10

ASOUND_CARD=rockchip$1

echo "$TEST_ITEM Testing ..."

if [ "$2" != "" ];then
	RECORD_TIME=$2
fi

echo "record file: $RECORD_FILE"
echo "RECORD_TIME = $RECORD_TIME"

CARD_ID=`cat /proc/asound/cards | grep ${ASOUND_CARD} | awk '{printf $1}'`
echo CARD_ID=$CARD_ID

if [ $ASOUND_CARD == "rt5640" ];then
    amixer -c $CARD_ID cset name='DAI select' '1:1|2:2'
    amixer -c $CARD_ID cset name='RECMIXL BST1 Switch' 1
    amixer -c $CARD_ID cset name='RECMIXR BST1 Switch' 1
    amixer -c $CARD_ID cset name='RECMIXL BST2 Switch' 0
    amixer -c $CARD_ID cset name='RECMIXR BST2 Switch' 0
    amixer -c $CARD_ID cset name='Stereo ADC1 Mux' 'ADC'
    amixer -c $CARD_ID cset name='Stereo ADC MIXL ADC1 Switch' 1
    amixer -c $CARD_ID cset name='Stereo ADC MIXR ADC1 Switch' 1
    amixer -c $CARD_ID cset name='Stereo ADC MIXL ADC2 Switch' 0
    amixer -c $CARD_ID cset name='Stereo ADC MIXR ADC2 Switch' 0
    amixer -c $CARD_ID cset name='ADC Capture Switch' 1 1
    amixer -c $CARD_ID cset name='ADC Capture Volume' 50% 

    amixer -c $CARD_ID cset name='ADC Boost Gain' 1 1
    amixer -c $CARD_ID cset name='IN Capture Volume' 17 17
    amixer -c $CARD_ID cset name='IN1 Boost' 3
    amixer -c $CARD_ID cset name='IN2 Boost' 3
    amixer -c $CARD_ID cset name='IN3 Boost' 3

fi

arecord -Dplughw:$CARD_ID,0 -f S16_LE -r 16000 -d $RECORD_TIME -t wav $RECORD_FILE

echo "$TEST_ITEM Test Finish"
