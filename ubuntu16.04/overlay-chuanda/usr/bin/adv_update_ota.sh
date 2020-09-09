#!/bin/bash

###########################################################################
## Function : get update image from ftp or from u-disk, and auto update
## Modify List : 
##     1. First init 2020-09-08 	V1.0.1
##     2. 
###########################################################################

##-------------------------------------------------------------------------
OTG_PATH="/oem/update_ota"
FTP_CONFIG_FILE="/etc/ftp_ota.conf"
FTP_DOWNLOAD_LOG=ftp_update_download_image.log

FTP_DOWNLOAD_TRY_COUNT=2
FTP_DOWNLOAD_TRY_DELAY=60

WAIT_TIME=10
TRY_COUNT=10
##-------------------------------------------------------------------------
## get FTP configuration from FTP_CONFIG_FILE.
##-------------------------------------------------------------------------

function get_ftp_configuration()
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
    pftp -v -n ${FTP_SERVER_IP} <<-EOF
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
    try_time=$FTP_DOWNLOAD_TRY_COUNT

    if [ -f "$FTP_DOWNLOAD_LOG" ]; then
        rm $FTP_DOWNLOAD_LOG
    fi

    while [ $try_time -gt 0 ]
    do
        pftp -v -n ${FTP_SERVER_IP} >$FTP_DOWNLOAD_LOG <<-EOF
            user "${FTP_USER}" "${FTP_PASSWORD}"
            prompt
            binary
            pwd
            cd $FTP_PATH
            mget update.img.md5
            mget update.img
            close
            quit
		EOF

        ftp_status=`grep "Transfer complete" $FTP_DOWNLOAD_LOG -ic`
        if [ "$ftp_status" == "2" ];then
            echo "Ftp download update.img sucessful"
            break
        else
            # clean error image
            if [ -f "/userdata/update.img" ]; then
                rm /userdata/update.img
            fi

            if [ -f "/userdata/update.img.md5" ]; then
                rm /userdata/update.img.md5
            fi
            echo "Ftp download update.img Fail, try time left : $try_time"
        fi

        sleep $FTP_DOWNLOAD_TRY_DELAY
        let try_time--
    done

    if [ -f "$FTP_DOWNLOAD_LOG" ]; then
        rm $FTP_DOWNLOAD_LOG
    fi
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
        mget PreUpdate.sh
        mget PostUpdate.sh
        close
        quit
	EOF

    sync
    chmod +x PreUpdate.sh
    chmod +x PostUpdate.sh
}

function udisk_get_image()
{
    cd /userdata
    cp /media/root/UPDATE/update.img.md5 ./
    cp /media/root/UPDATE/update.img ./
    sync
}

function udisk_get_update_shell()
{
    cd $OTG_PATH

    cp /media/root/UPDATE/PreUpdate.sh ./
    cp /media/root/UPDATE/PostUpdate.sh ./
    sync
    chmod +x PreUpdate.sh
    chmod +x PostUpdate.sh
}

function update_clean()
{
    echo "Make clean for updating..."
    if [ -f "/userdata/update.img" ]; then
        rm /userdata/update.img
    fi

    if [ -f "/userdata/update.img.md5" ]; then
        rm /userdata/update.img.md5
    fi

    if [ ! -d "$OTG_PATH" ]; then
        mkdir -p $OTG_PATH
    fi
    rm -rf $OTG_PATH/*
    sync
}

# --------------------------------------------------------- #
# exec update after shell
if [ -f "$OTG_PATH/update_flag" ]; then
    echo "Exist updat flag"
    rm $OTG_PATH/update_flag
    if [ -f "$OTG_PATH/PostUpdate.sh" ]; then
        echo "Exec PostUpdate.sh"
        $OTG_PATH/PostUpdate.sh
        rm $OTG_PATH/PostUpdate.sh
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
update_clean

# check for FTP configuration
if [ "$UPDATE_RESOURCE" == "FTP" ]; then
    if [ ! -f "$FTP_CONFIG_FILE" ]; then
        echo "Don't exist FTP configuration file $FTP_CONFIG_FILE"
        exit 0
    fi
fi

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
    update_clean
    exit 0
fi

version_des=`cat $OTG_PATH/version`
rm $OTG_PATH/version
if [ "$version_src" == "$version_des" ]; then
    echo "Version is the same, Already updated!"
    update_clean
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
    update_clean
    exit 0
fi

if [ ! -f "/userdata/update.img.md5" ]; then
    echo "Not found update.img.md5"
    update_clean
    exit 0
fi

# check md5
md5src=`cat /userdata/update.img.md5 | awk '{print $1}'`
md5des=`md5sum /userdata/update.img | awk '{print $1}'`
if [ "$md5src" != "$md5des" ]; then
    echo "update.img: md5 value check fail"
    update_clean
    exit 0
fi

rm /userdata/update.img.md5
sync

# before update shell
if [ -f "$OTG_PATH/PreUpdate.sh" ]; then
    echo "Exec PreUpdate.sh"
    $OTG_PATH/PreUpdate.sh
    rm $OTG_PATH/PreUpdate.sh
fi

# update image
/usr/bin/update-ota
