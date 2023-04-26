
-------------------------------------------------------
## loop test can0 & can1 ##
# Short pin2 of DB9 port on can0 to pin2 of DB9 port on can1
# Short pin7 of DB9 port on can0 to pin7 of DB9 port on can1
# can0 receive & can1 send
/tools/test/adv/can/can_test.sh can0 can1

# can1 receive & can0 send
/tools/test/adv/can/can_test.sh can1 can0

-------------------------------------------------------
## loop test can0 & can1 FD ##
# Short pin2 of DB9 port on can0 to pin2 of DB9 port on can1
# Short pin7 of DB9 port on can0 to pin7 of DB9 port on can1
# can0 receive & can1 send
/tools/test/adv/can/canfd_test.sh can0 can1

# can1 receive & can0 send
/tools/test/adv/can/canfd_test.sh can1 can0

-------------------------------------------------------
