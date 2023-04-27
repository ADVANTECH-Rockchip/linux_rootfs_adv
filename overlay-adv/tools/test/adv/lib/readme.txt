
-------------------------------------------------------
## power on off test ##

cp /tools/test/adv/lib/adv-poweroff.service /lib/systemd/system/
systemctl enable adv-poweroff.service

-------------------------------------------------------
## static IP ##

cp /tools/test/adv/lib/10-eth0-static.network /etc/network/interfaces.d/
cp /tools/test/adv/lib/10-eth1-static.network /etc/network/interfaces.d/

-------------------------------------------------------
