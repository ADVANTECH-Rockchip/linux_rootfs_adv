#!/bin/bash

sleep 10

flag1=`systemctl list-units |grep systemd-logind |awk {'print $3'}`
if [ x$flag1 != "xactive" ];then
    echo "[ADV] systemd-logind boot fail" > /dev/ttyFIQ0
fi

flag2=`systemctl list-units |grep systemd-user-sessions |awk {'print $3'}`
if [ x$flag2 != "xactive" ];then
    echo "[ADV] systemd-user-sessions boot fail" > /dev/ttyFIQ0
fi

flag3=`systemctl list-units |grep lightdm |awk {'print $3'}`
if [ x$flag3 != "xactive" ];then
    echo "[ADV] lightdm boot fail" > /dev/ttyFIQ0
fi

flag4=`systemctl list-units |grep serial-getty@ttyFIQ0 |awk {'print $3'}`
if [ x$flag4 != "xactive" ];then
    echo "[ADV] serial-getty@ttyFIQ0 boot fail" > /dev/ttyFIQ0
fi


if [[ x$flag1 == "xactive" ]] && [[ x$flag2 == "xactive" ]] && [[ x$flag3 == "xactive" ]] && [[ x$flag4 == "xactive" ]];then
    # disable WDT
    echo "[ADV] service boot success" > /dev/ttyFIQ0
    if [ -f "/sys/class/adv_bootprocess_class/adv_bootprocess_device/timer_flag" ];then
        echo 1 > /sys/class/adv_bootprocess_class/adv_bootprocess_device/timer_flag
    fi
else
    echo "[ADV] service boot fail" > /dev/ttyFIQ0
fi


