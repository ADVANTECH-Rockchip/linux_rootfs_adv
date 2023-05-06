
-------------------------------------------------------
## power on off test ##

cp /tools/test/adv/lib/adv-poweroff.service /lib/systemd/system/
systemctl enable adv-poweroff.service

-------------------------------------------------------
## static IP ##
cp "/tools/test/adv/lib/Wired connection 1.nmconnection"  /etc/NetworkManager/system-connections/
cp "/tools/test/adv/lib/Wired connection 2.nmconnection"  /etc/NetworkManager/system-connections/

systemctl restart NetworkManager.service
ifconfig eth0 down
ifconfig eth1 down
ifconfig eth0 up
ifconfig eth1 up

-------------------------------------------------------
