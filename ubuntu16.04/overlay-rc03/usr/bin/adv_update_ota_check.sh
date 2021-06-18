#!/bin/bash

###########################################################################
## Function : get update image from ftp or from u-disk, and auto update
## Modify List : 
##     1. First init 2020-09-08 	V1.0.1
##     2. 
###########################################################################

##-------------------------------------------------------------------------
# error code
ERR_PROCESS_IS_RUNNING="-1"
ERR_PROJECT_CONFIG="-2"
ERR_FTP_CONFIG="-3"
ERR_UPDATE_LIST="-4"
ERR_VERSION="-5"
ERR_DOWNLOAD_IMAGE="-6"
ERR_DOWNLOAD_TIMEOUT="-7"

ERR_UPDATE_FLOW="-20"
##-------------------------------------------------------------------------
OTA_PATH="/oem/update_ota"
OTA_ERR_CODE="${OTA_PATH}/update_err_code"

OTA_UPDATE_CHECK_FLAG="${OTA_PATH}/update_check_flag"
OTA_UPDATE_IMAGE_SIZE="${OTA_PATH}/update_image_size"

UDISK_MOUNT_PATH="/media/$USER/UPDATE"

FTP_CONFIG_FILE="/etc/ftp_ota.conf"
FTP_IMAGE_LIST_LOG=$OTA_PATH/ftp_update_image_list.log

FTP_DOWNLOAD_TRY_COUNT=2
FTP_DOWNLOAD_TRY_DELAY=60

WAIT_TIME=10
TRY_COUNT=10

##-------------------------------------------------------------------------
## get FTP configuration from FTP_CONFIG_FILE.
##-------------------------------------------------------------------------
function get_ftp_configuration()
{
    echo "Get ftp configuration from $FTP_CONFIG_FILE"
    FTP_SERVER_IP=`grep ftpserver_ip $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_USER=`grep ftpserver_user $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_PASSWORD=`grep ftpserver_passwd $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_PATH=`grep ftpserver_dirname $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`

    echo "FTP_SERVER_IP : $FTP_SERVER_IP"
    echo "FTP_USER      : $FTP_USER"
    echo "FTP_PASSWORD  : $FTP_PASSWORD"
    echo "FTP_PATH      : $FTP_PATH"
}

function ftp_get_image_list()
{
    pftp -v -n ${FTP_SERVER_IP} >$FTP_IMAGE_LIST_LOG <<-EOF
        user "$FTP_USER" "$FTP_PASSWORD"
        prompt
        binary
	    pwd
	    cd $FTP_PATH
        ls -l
        close
        quit
	EOF
}

function ftp_get_version()
{
    cd $OTA_PATH
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

function update_clean()
{
    if [ -f "/userdata/update.img" ]; then
        rm /userdata/update.img
    fi

    if [ -f "/userdata/update.img.md5" ]; then
        rm /userdata/update.img.md5
    fi

    if [ ! -d "$OTA_PATH" ]; then
        mkdir -p $OTA_PATH
    fi
    rm -rf $OTA_PATH/*
    sync
}

function update_exit()
{
    update_clean
    echo "$0" > $OTA_ERR_CODE
    exit 1
}

##-------------------------------------------------------------------------
echo "$0 begin ..."

if [ ! -d "$OTA_PATH" ]; then
    mkdir -p $OTA_PATH
fi

if [ -f "$OTA_UPDATE_CHECK_FLAG" ]; then
    rm $OTA_UPDATE_CHECK_FLAG
fi

echo 0 > $OTA_ERR_CODE
#check self
SELF_NAME=$0
UPDATE_PROCESS=`ps -ef | grep "$SELF_NAME" | grep -v 'grep'`
UPDATE_PROCESS_COUNT=`echo $UPDATE_PROCESS | grep -c "$SELF_NAME"`
if [ $UPDATE_PROCESS_COUNT -gt 1 ]; then
    echo "Fail : $SELF_NAME process is already running!"
    update_exit $ERR_PROCESS_IS_RUNNING
fi

#check get image process
UPDATE_SERVICE="adv_update_ota_get_image.sh"
UPDATE_PROCESS=`ps -ef | grep "$UPDATE_SERVICE" | grep -v 'grep'`
UPDATE_PROCESS_COUNT=`echo $UPDATE_PROCESS | grep -c "$UPDATE_SERVICE"`
if [ $UPDATE_PROCESS_COUNT -gt 0 ]; then
    echo "Fail : $UPDATE_SERVICE process is already running!"
    update_exit $ERR_PROCESS_IS_RUNNING
fi

#check update service
UPDATE_SERVICE="adv_update_ota.sh"
UPDATE_PROCESS=`ps -ef | grep "$UPDATE_SERVICE" | grep -v 'grep'`
UPDATE_PROCESS_COUNT=`echo $UPDATE_PROCESS | grep -c "$UPDATE_SERVICE"`
if [ $UPDATE_PROCESS_COUNT -gt 0 ]; then
    echo "Fail : $UPDATE_SERVICE process is running, please wait!"
    update_exit $ERR_PROCESS_IS_RUNNING
fi

# check project
SUPPORT_PROJECT=("RSB-3710" "RSB-4710" "ROM-5780" "RC03")

SUPPORT_UPDATE=FALSE
if [ ! -f "/proc/board" ]; then
    echo "Fail : Fail to get project configuration"
    update_exit $ERR_PROJECT_CONFIG
fi

ADV_PROJECT=`cat /proc/board | awk {'print $1'}`

for i in "${SUPPORT_PROJECT[@]}";
do
    if [ "$ADV_PROJECT" == "$i" ]; then
        SUPPORT_UPDATE=TRUE
    fi
done

if [ "$SUPPORT_UPDATE" == "FALSE" ]; then
    echo "Fail : Project $ADV_PROJECT don't support update"
    update_exit $ERR_PROJECT_CONFIG
fi

# --------------------------------------------------------- #
# exec update before shell
UPDATE_RESOURCE=FTP
if [ -d "$UDISK_MOUNT_PATH" ]; then
    UPDATE_RESOURCE=UDISK
fi
echo "Info : Update from $UPDATE_RESOURCE"

# clean 
update_clean

# check for FTP configuration
if [ "$UPDATE_RESOURCE" == "FTP" ]; then
    if [ ! -f "$FTP_CONFIG_FILE" ]; then
        echo "Fail : Don't exist $FTP_CONFIG_FILE"
        update_exit $ERR_FTP_CONFIG
    fi
fi

# check file list : version update.img update.img.md5
if [ "$UPDATE_RESOURCE" == "UDISK" ]; then
    if [ ! -f "$UDISK_MOUNT_PATH/version" ]; then
        echo "Fail : Don't exist version in $UPDATE_RESOURCE"
        update_exit $ERR_UPDATE_LIST
    fi

    if [ ! -f "$UDISK_MOUNT_PATH/update.img.md5" ]; then
        echo "Fail : Don't exist update.img.md5 in $UPDATE_RESOURCE"
        update_exit $ERR_UPDATE_LIST
    fi

    if [ ! -f "$UDISK_MOUNT_PATH/update.img" ]; then
        echo "Fail : Don't exist update.img in $UPDATE_RESOURCE"
        update_exit $ERR_UPDATE_LIST
    fi

    total_size=`ls -al "$UDISK_MOUNT_PATH/update.img" |  awk '{print $5}'`
    echo $total_size > $OTA_UPDATE_IMAGE_SIZE
else
    get_ftp_configuration
    for ((i=1; i<=$TRY_COUNT; i++))
    do
        ftp_get_image_list
        ftp_status=`grep "Not Connect" $FTP_IMAGE_LIST_LOG -ic`
        if [ "$ftp_status" == "0" ];then
            break
        else
            sleep 1
        fi
    done
    temp=`grep -c "version" $FTP_IMAGE_LIST_LOG`
    if [ "$temp" == "0" ]; then
        echo "Fail : Don't exist version in $UPDATE_RESOURCE"
        update_exit $ERR_UPDATE_LIST
    fi

    temp=`grep -c "update.img.md5" $FTP_IMAGE_LIST_LOG`
    if [ "$temp" == "0" ]; then
        echo "Fail : Don't exist update.img.md5 in $UPDATE_RESOURCE"
        update_exit $ERR_UPDATE_LIST
    fi

    temp=`grep "update.img" $FTP_IMAGE_LIST_LOG | grep -v "update.img.md5" | grep -c "update.img"`
    if [ "$temp" == "0" ]; then
        echo "Fail : Don't exist update.img in $UPDATE_RESOURCE"
        update_exit $ERR_UPDATE_LIST
    fi

    total_size=`grep "update.img" $FTP_IMAGE_LIST_LOG | grep -v "update.img.md5" |  awk '{print $5}'`
    echo $total_size > $OTA_UPDATE_IMAGE_SIZE
fi

# check version
version_src=`cat /proc/board | awk {'print $3'}`

echo "Info : Get version from $UPDATE_RESOURCE ..."
if [ "$UPDATE_RESOURCE" == "UDISK" ]; then
    for ((i=1; i<=$TRY_COUNT; i++))
    do
        if [ ! -f "$UDISK_MOUNT_PATH/version" ]; then
            sleep 1
        else
            cp -rf $UDISK_MOUNT_PATH/version $OTA_PATH/version
            break
        fi
    done
else
    get_ftp_configuration
    for ((i=1; i<=$TRY_COUNT; i++))
    do
        ftp_get_version
        if [ ! -f "$OTA_PATH/version" ]; then
            sleep 1
        else
            break
        fi
    done
fi

if [ ! -f "$OTA_PATH/version" ]; then
    echo "Fail : Don't exist version file in $UPDATE_RESOURCE"
    update_exit $ERR_UPDATE_LIST
fi

version_des=`cat $OTA_PATH/version`
rm $OTA_PATH/version
if [ "$version_src" == "$version_des" ]; then
    echo "Fail : Version is already $version_src, don't need to update!"
    update_exit $ERR_UPDATE_LIST
fi

echo "Info : Get version done"
echo "Info : Version in device is : $version_src"
echo "Info : Will update to Version : $version_des"

# set Flag to get update images
echo "OK" > $OTA_UPDATE_CHECK_FLAG
