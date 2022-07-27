#!/bin/bash

sleep 30
if [ -f /data/BurnIn/atx ];then
    poweroff
else
    reboot
fi


