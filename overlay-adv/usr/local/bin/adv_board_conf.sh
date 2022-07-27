#!/bin/bash

DIR=`dirname $0`

export ADV_BOARD=`cat /proc/board | awk '{printf $1}'`

case $ADV_BOARD in
    RSB-3710)
        export PORT_4G="/dev/ttyUSB2"
        export PORT_ETH=(eth0 eth1)
        export PORT_SER=(ttyS0 ttyS4)
        export PORT_GPIO=(496 497 498 499 504 505 506 507 508 509 510 511)
        ;;
    RSB-4710)
        export PORT_4G="/dev/ttyUSB6"
        export PORT_ETH=(eth0 eth1)
        export PORT_SER=(ttyS4 ttyUSB0 ttyUSB1 ttyUSB2 ttyUSB3)
        export PORT_GPIO=(72 50 124 132 8)
        ;;
    ROM-5780)
        export PORT_4G="/dev/ttyUSB6"
        export PORT_ETH=(eth0)
        export PORT_SER=(ttyS0 ttyS4)
        export PORT_GPIO=(34 35 41 42 45 50 52 54 55 66 67 149)
        ;;
    ROM-5781)
        export PORT_4G="/dev/ttyUSB6"
        export PORT_ETH=(eth0)
        export PORT_SER=(ttyS0 ttyS4)
        export PORT_GPIO=(34 35 41 42 45 50 52 54 55 66 67 149)
        ;;
    *)
        echo "Error: Not support board $ADV_BOARD !!!"
        ;;
esac

echo "===================================================="
echo "Board         : $ADV_BOARD"
echo "PORT 4G       : $PORT_4G"
echo "PORT Eth      : ${PORT_ETH[@]}"
echo "PORT Serial   : ${PORT_SER[@]}"
echo "PORT GPIO     : ${PORT_GPIO[@]}"
echo "===================================================="

