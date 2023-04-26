
-------------------------------------------------------
## RS-23s single port loop test ##
# 2-wire 
# short PIN2 to PIN3 of DB9 port
/tools/test/adv/uart/serial_test /dev/ttyS0 115200 n 10 2


# 4-wire 
# short PIN2 to PIN3 of DB9 port
# short PIN7 to PIN8 of DB9 port
/tools/test/adv/uart/serial_test /dev/ttyS0 115200 h 10 2
-------------------------------------------------------

