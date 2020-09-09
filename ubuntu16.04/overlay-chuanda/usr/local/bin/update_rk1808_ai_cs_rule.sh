cat <<EOF > "91-rk1808-ai-cs.rules"
SUBSYSTEM=="usb", ATTR{idVendor}=="2207", MODE="0666"
EOF

cp -f 91-rk1808-ai-cs.rules /etc/udev/rules.d/
udevadm control --reload-rules
udevadm trigger
ldconfig
rm 91-rk1808-ai-cs.rules
