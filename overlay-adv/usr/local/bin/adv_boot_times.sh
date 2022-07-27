#!/bin/bash
#########################################################
#   description: PowerOnOff test script
#   usage: PowerOnOff.sh
#   version:2019/11/22 by yanwei
########################################################

DIR=`dirname $0`
logFile="/etc/boottimes"

TRY_TIME_MAX=20

function bootCount()
{
	if [ -e ${logFile} ] ; then 
		logNu=`cat ${logFile}`
		countNu=$((${logNu}+1))
		echo ${countNu} > ${logFile}
	else
		touch ${logFile}
		echo "1" > ${logFile}
	fi
	sync
}

#detect 4G
function detect_4g()
{
    if [ -c $PORT_4G ]; then
        echo "Detected 4G module"
    else
        echo "Detected 4G module error"
        exit
    fi
}

#detect ethernet
function detect_eth()
{
    for i in "${PORT_ETH[@]}";
    do
        TRY_TIME=$TRY_TIME_MAX
        while [ $TRY_TIME -gt 0 ]
        do
            if [ -e /sys/class/net/$i/address ]; then
                break
            fi
            let TRY_TIME--
            sleep 1
        done

        if [ $TRY_TIME -gt 0 ];then
            echo "Detected $i module"
        else
            echo "Detected $i module error"
            exit
        fi
    done
}

#detect wlan
function detect_wlan()
{
    TRY_TIME=$TRY_TIME_MAX
    while [ $TRY_TIME -gt 0 ]
    do
        if [ -e /sys/class/net/wlan0/address ]; then
            break
        fi
        let TRY_TIME--
        sleep 1
    done

    if [ $TRY_TIME -gt 0 ];then
        echo "Detected wlan module"
    else
        echo "Detected wlan module error"
        exit
    fi
}

#detect bluetooth
function detect_bt()
{
    TRY_TIME=$TRY_TIME_MAX
    while [ $TRY_TIME -gt 0 ]
    do
        BTCOUNT=`hciconfig | grep "BD Address" -c`
        if [ $BTCOUNT -ge 1 ];then
            break
        fi
        let TRY_TIME--
        sleep 1
    done

    if [ $TRY_TIME -gt 0 ];then
        echo "Detected bt module"
    else
        echo "Detected bt module error"
        exit
    fi
}

# sleep 25
# source $DIR/adv_board_conf.sh
# detect_eth
# detect_wlan
# detect_bt
# detect_4g

bootCount


