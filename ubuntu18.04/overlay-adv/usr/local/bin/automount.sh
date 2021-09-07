#!/bin/sh
#
# Called from udev
#
# Attempt to mount any added block devices and umount any removed devices
MOUNT="/bin/mount"
PMOUNT="/usr/bin/pmount"
UMOUNT="/bin/umount"

MOUNT_PATH=/run/media

automount() {	
	name="`basename "$DEVNAME"`"

	! test -d "${MOUNT_PATH}/$name" && mkdir -p "${MOUNT_PATH}/$name"
	# Silent util-linux's version of mounting auto
	if [ "x`readlink $MOUNT`" = "x/bin/mount.util-linux" ] ;
	then
		MOUNT="$MOUNT -o silent"
	fi
	
	# If filesystem type is vfat, change the ownership group to 'disk', and
	# grant it with  w/r/x permissions.
	case $ID_FS_TYPE in
	vfat|fat)
		MOUNT="$MOUNT -o umask=007,uid=`awk -F':' '/^linaro/{print $3}' /etc/group`"
		;;
	exfat)
		rm_dir "${MOUNT_PATH}/$name"
		exit 0
		;;
	# TODO
	*)
		;;
	esac

	if ! $MOUNT -t auto $DEVNAME "${MOUNT_PATH}/$name"
	then
		rm_dir "${MOUNT_PATH}/$name"
	else
		touch "/tmp/.automount-$name"
	fi
}
	
rm_dir() {
	# We do not want to rm -r populated directories
	if test "`find "$1" | wc -l | tr -d " "`" -lt 2 -a -d "$1"
	then
		! test -z "$1" && rm -r "$1"
	fi
}

# No ID_FS_TYPE for cdrom device, yet it should be mounted
name="`basename "$DEVNAME"`"
[ -e /sys/block/$name/device/media ] && media_type=`cat /sys/block/$name/device/media`

if [ "$ACTION" = "add" ] && [ -n "$DEVNAME" ] && [ -n "$ID_FS_TYPE" -o "$media_type" = "cdrom" ]; then
	if [ -x "$PMOUNT" ]; then
		$PMOUNT $DEVNAME 2> /dev/null
	elif [ -x $MOUNT ]; then
    		$MOUNT $DEVNAME 2> /dev/null
	fi
	
	# If the device isn't mounted at this point, it isn't
	# configured in fstab (note the root filesystem can show up as
	# /dev/root in /proc/mounts, so check the device number too)
	if expr $MAJOR "*" 256 + $MINOR != `stat -c %d /`; then
		grep -q "^$DEVNAME " /proc/mounts || automount
	fi
fi

if [ "$ACTION" = "remove" ] || [ "$ACTION" = "change" ] && [ -x "$UMOUNT" ] && [ -n "$DEVNAME" ]; then
	for mnt in `cat /proc/mounts | grep "$DEVNAME" | cut -f 2 -d " " `
	do
		$UMOUNT $mnt
	done
	
	# Remove empty directories from auto-mounter
	name="`basename "$DEVNAME"`"
	test -e "/tmp/.automount-$name" && rm_dir "${MOUNT_PATH}/$name"
fi
