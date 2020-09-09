#!/bin/bash

###########################################################################
## Function : get update image from ftp or from u-disk, and auto update
## Modify List : 
##     1. First init 2020-09-08 	V1.0.1
##     2. 
###########################################################################

##-------------------------------------------------------------------------
## The following parameters should be modified according customer's FTP configuration.
## 
FTP_SERVER_IP=172.21.170.48
FTP_USER=yunjin
FTP_PASSWORD=jiang001
FTP_PATH="code/rk_update/rsb4710"
FTP_CONFIG_FILE="/etc/ftp_config.ini"
##-------------------------------------------------------------------------
OTG_PATH="/oem/update_ota"
LOG_FILE=$OTG_PATH/update.log
WAIT_TIME=10
TRY_COUNT=10
##-------------------------------------------------------------------------
## get FTP configuration from /etc/ftp_config.ini.
##-------------------------------------------------------------------------

get_ftp_configuration()
{
    FTP_SERVER_IP=`grep ftpserver_ip $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_USER=`grep ftpserver_user $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_PASSWORD=`grep ftpserver_passwd $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_PATH=`grep ftpserver_dirname $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
	
	echo "FTP_SERVER_IP : $FTP_SERVER_IP"
	echo "FTP_USER      : $FTP_USER"
	echo "FTP_PASSWORD  : $FTP_PASSWORD"
	echo "FTP_PATH      : $FTP_PATH"		
}

function ftp_get_version()
{
    cd $OTG_PATH
    ftp -v -n ${FTP_SERVER_IP} <<-EOF
        user "${FTP_USER}" "${FTP_PASSWORD}"
        prompt
        binary
        pwd
        cd $FTP_PATH
        mget version
        close
        quit
	EOF
}

function ftp_get_image()
{
    cd /userdata
    pftp -v -n ${FTP_SERVER_IP} <<-EOF
        user "${FTP_USER}" "${FTP_PASSWORD}"
        prompt
        binary
        pwd
        cd $FTP_PATH
        mget update.img
        mget update.img.md5
        close
        quit
	EOF
    sync
}

function ftp_get_update_shell()
{
    cd $OTG_PATH

    pftp -v -n ${FTP_SERVER_IP} <<-EOF
        user "${FTP_USER}" "${FTP_PASSWORD}"
        prompt
        binary
        pwd
        cd $FTP_PATH
        mget 00_update_before.sh
        mget 01_update_after.sh
        close
        quit
	EOF

    sync
	chmod +x 00_update_before.sh
    chmod +x 01_update_after.sh
}

function udisk_get_image
{
    cd /userdata
    cp /media/root/UPDATE/update.img ./
    cp /media/root/UPDATE/update.img.md5 ./
    sync
}

function udisk_get_update_shell
{
    cd $OTG_PATH

    cp /media/root/UPDATE/00_update_before.sh ./
    cp /media/root/UPDATE/01_update_after.sh ./
	sync
	chmod +x 00_update_before.sh
    chmod +x 01_update_after.sh
}

# --------------------------------------------------------- #
# exec update after shell
if [ -f "$OTG_PATH/update_flag" ]; then
    echo "Exist updat flag"
    rm $OTG_PATH/update_flag
	if [ -f "$OTG_PATH/01_update_after.sh" ]; then
        echo "Exec 01_update_after.sh"
        $OTG_PATH/01_update_after.sh
	fi
    exit 0
fi

# --------------------------------------------------------- #
# exec update before shell
UPDATE_RESOURCE=FTP
if [ -d "/media/root/UPDATE" ]; then
    UPDATE_RESOURCE=UDISK
fi
echo "Update from $UPDATE_RESOURCE"

# clean 
echo "Make clean for updating..."

if [ -f "/userdata/update.img" ]; then
    rm /userdata/update.img
fi

if [ -f "/userdata/update.img.md5" ]; then
    rm /userdata/update.img.md5
fi

if [ -d "$OTG_PATH" ]; then
    rm -rf $OTG_PATH
fi
mkdir -p $OTG_PATH

sync

#wait time
sleep $WAIT_TIME

# check version
version_src=`cat /proc/board | awk {'print $3'}`

echo "Get version from $UPDATE_RESOURCE ..."
if [ "$UPDATE_RESOURCE" == "UDISK" ]; then
    for ((i=1; i<=$TRY_COUNT; i++))
    do
        echo "TRY_COUNT : $i"
        if [ ! -f "/media/root/UPDATE/version" ]; then
            sleep 1
        else
            cp -rf /media/root/UPDATE/version $OTG_PATH/version
			break
        fi
    done
else
    get_ftp_configuration
    for ((i=1; i<=$TRY_COUNT; i++))
    do
        echo "TRY_COUNT : $i"
        ftp_get_version
        if [ ! -f "$OTG_PATH/version" ]; then
            sleep 1
        else
            break
        fi
    done
fi

if [ ! -f "$OTG_PATH/version" ]; then
	echo "No version file in $UPDATE_RESOURCE, Update abort"
	exit 0
fi
		
version_des=`cat $OTG_PATH/version`
rm $OTG_PATH/version
if [ "$version_src" == "$version_des" ]; then
	echo "Version is the same, Already updated!"
	exit 0
fi

# get update image
if [ "$UPDATE_RESOURCE" == "UDISK" ]; then
    udisk_get_image
    udisk_get_update_shell
else
    ftp_get_image
    ftp_get_update_shell
fi

# check update image
if [ ! -f "/userdata/update.img" ]; then
    echo "Not found update.img"
    exit 0
fi

if [ ! -f "/userdata/update.img.md5" ]; then
    echo "Not found update.img.md5"
    exit 0
fi

# check md5
md5src=`cat /userdata/update.img.md5 | awk '{print $1}'`
md5des=`md5sum /userdata/update.img | awk '{print $1}'`
if [ "$md5src" != "$md5des" ]; then
    echo "update.img: md5 value check fail"
    exit 0
fi

rm /userdata/update.img.md5
sync

# before update shell
if [ -f "$OTG_PATH/00_update_before.sh" ]; then
    echo "Exec 00_update_before.sh"
    $OTG_PATH/00_update_before.sh
    rm $OTG_PATH/00_update_before.sh
fi

# update image
/usr/bin/update-ota
