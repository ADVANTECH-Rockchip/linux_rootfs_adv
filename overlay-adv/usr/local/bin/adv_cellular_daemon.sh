#!/bin/bash
#
# Created on Fri Dec 2 2022
#
# Copyright (C) 1983-2022 Advantech Co., Ltd.
# Author: Yunjin.Jiang, yunjin.jiang@advantech.com.cn
#
# Function: monitor cellular module & SIM status

# config global value
MAX_MODULE_READY_SEC=300
PING_INTERVAL=${PING_INTERVAL:-1h}
PING_INTERVAL_LONG=${PING_INTERVAL_LONG:-8h}
SIGNAL_QUALITY_THRESHOLD=20
MODULE_RESET_THRESHOLD=3
MAX_PING_ERROR_COUNT=12
MAX_SIM_DETECT_COUNT=3

# local global value
SIM_DETECT_COUNT=0
MODULE_RESET_COUNT=0
MODEM_INDEX=0
SIGNAL_QUALITY=0

reset_module()
{
    let MODULE_RESET_COUNT+=1
    echo "reset module, reset count: $MODULE_RESET_COUNT"
    echo 1 > /sys/bus/platform/devices/misc-adv-gpio/minipcie_reset
    sleep $MAX_MODULE_READY_SEC
    get_modem_index
}

is_module_exist()
{
	local ret=0

    ret=`mmcli -L | grep -ci QUECTEL`

	if [ $ret -eq 0 ];then
        echo "cellular module doesn't exist"
    else
        echo "cellular module exist"
    fi

    return $ret
}

get_modem_index()
{
    MODEM_INDEX=$(
	    mmcli -L | 
		grep -Eo '/org/freedesktop/ModemManager1/Modem/[0-9]+' | 
		sed -En 's|/org/freedesktop/ModemManager1/Modem/([0-9]+)|\1|p' | 
		head -1
		)

    echo "ModemIndex is $MODEM_INDEX"
}

get_signal_quality()
{
    SIGNAL_QUALITY=$(
	    mmcli -m $MODEM_INDEX | 
        grep -Eo "signal quality: [0-9]+" | 
        sed -En 's|signal quality: ([0-9]+)|\1|p'
		)

    echo "SIGNAL_QUALITY is $SIGNAL_QUALITY"
}

is_module_connected_exist()
{
	local ret=0 

    ret=$(
	    mmcli -m $MODEM_INDEX | 
		grep "connected" -c
		)

	if [ $ret -eq 0 ];then
        echo "Module network doesn't connect"
    else
        echo "Module network has been connected"
    fi
    return $ret
}

is_sim_card_exist()
{
	local ret=0 

    ret=$(
	    mmcli -m $MODEM_INDEX | 
		grep "sim-missing" -c
		)

	if [ $ret -ne 0 ];then
        echo "SIM card doesn't exist"
    else
        echo "SIM card exist"
    fi
    return $ret
}

# check nerwork，timeout 5s
ping_network() {
    # ping return 0 if success
    # return 1 if packet loose
    # return 2 if error
	local net_port=wwan0

    ping -I $net_port -c1 -W 5 8.8.8.8 &>/dev/null
}

check_network()
{
    local ping_count=0

    while [ $ping_count -lt $MAX_PING_ERROR_COUNT ]; do
        let ping_count+=1
        echo ping_count:$ping_count
        ping_network
        if [ $? -eq 0 ];then
            break
        fi
    done

    if [ $ping_count -ge $MAX_PING_ERROR_COUNT ];then
        echo "network error"
        reset_module
    else
        let MODULE_RESET_COUNT=0
        echo "network OK"
    fi
}

echo "cellular daemon start"
echo "sleep $MAX_MODULE_READY_SEC for cellular module ready"
sleep $MAX_MODULE_READY_SEC

# detect cellular module whether exist
is_module_exist
if [ $? -eq 0 ];then
    echo "cellular daemon stop"
    exit -1
fi

get_modem_index

# detect SIM card whether exist
while [ $SIM_DETECT_COUNT -lt $MAX_SIM_DETECT_COUNT ]; 
do
    let SIM_DETECT_COUNT+=1
    echo $SIM_DETECT_COUNT
    is_sim_card_exist
    if [ $? -eq 0 ];then
        break
    fi

    reset_module
done

if [ $SIM_DETECT_COUNT -ge $MAX_SIM_DETECT_COUNT ];then
    echo "cellular daemon stop"
    exit -1
fi


# Main Loop
while true;do
    # check SIM card
    is_sim_card_exist
    if [ $? -ne 0 ];then
        reset_module
    fi

    is_module_connected_exist
    MODEM_CONNET=$?
    # Net Connected
    if [ $MODEM_CONNET -ne 0 ];then
        echo "Connected"
        get_signal_quality
        if [ $SIGNAL_QUALITY -gt $SIGNAL_QUALITY_THRESHOLD ];then
            check_network
        fi
    else
        echo "Not Connected"
    fi

    if [ $MODULE_RESET_COUNT -gt $MODULE_RESET_THRESHOLD ];then
        sleep $PING_INTERVAL_LONG
    else
        sleep $PING_INTERVAL
    fi
    
done


