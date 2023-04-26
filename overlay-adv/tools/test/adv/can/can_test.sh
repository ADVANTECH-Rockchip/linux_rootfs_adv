#!/bin/bash
# usage :
# canbus_test.sh


TEST_ITEM="canbus"
DIR=`dirname $0`

PORT_R=$1
PORT_S=$2
BITRATE_A=1000000
# BITRATE_D=8000000


echo "$TEST_ITEM Testing ..."
echo "--------------------------------------------"
echo "R Port : ${PORT_R}"
echo "S Port : ${PORT_S}"
echo "A BitRate : ${BITRATE_A}"
# echo "D BitRate : ${BITRATE_D}"
echo "--------------------------------------------"

ip link set ${PORT_R} down
ip link set ${PORT_R} type can bitrate ${BITRATE_A} # dbitrate ${BITRATE_D} fd on
ip link set ${PORT_R} up
#ip -details link show ${PORT_R}
candump ${PORT_R} > $DIR/tmp_can.log &

ip link set ${PORT_S} down
ip link set ${PORT_S} type can bitrate ${BITRATE_A} # dbitrate ${BITRATE_D} fd on
ip link set ${PORT_S} up
#ip -details link show ${PORT_S}

for ((i=0; i<10;i++))
do
    cansend ${PORT_S} 123#55
    sleep 1
done

COUNT=`grep 55 -c $DIR/tmp_can.log`

if [ -f $DIR/tmp_can.log ]; then
    rm $DIR/tmp_can.log
fi

candump_pid=`ps |grep candump | awk {'print $1'}`
kill $candump_pid


if [ 10 -eq $COUNT ];then
    echo "$TEST_ITEM Test Pass"
else
    echo "$TEST_ITEM Test Fail"
fi
