#!/bin/sh
#export RSB-4710 gpio
echo 72 > /sys/class/gpio/export  #gpio1
echo 50 > /sys/class/gpio/export  #gpio2
#echo 131 > /sys/class/gpio/export  #gpio3
#echo 124 > /sys/class/gpio/export  #gpio4
#echo 132 > /sys/class/gpio/export  #gpio5
#echo 8 > /sys/class/gpio/export  #gpio6

#gpio1
chmod 777 /sys/class/gpio/gpio72/direction
chmod 777 /sys/class/gpio/gpio72/value
echo out > /sys/class/gpio/gpio72/direction

#gpio2
chmod 777 /sys/class/gpio/gpio50/direction
chmod 777 /sys/class/gpio/gpio50/value
echo out > /sys/class/gpio/gpio50/direction
