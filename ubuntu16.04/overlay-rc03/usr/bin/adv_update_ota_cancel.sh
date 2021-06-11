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
FTP_CONFIG_FILE="/etc/ftp_ota.conf"

##-------------------------------------------------------------------------
function get_ftp_configuration()
{
    echo "Info : Get ftp configuration from $FTP_CONFIG_FILE"

    FTP_SERVER_IP=`grep ftpserver_ip $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_USER=`grep ftpserver_user $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_PASSWORD=`grep ftpserver_passwd $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`
    FTP_PATH=`grep ftpserver_dirname $FTP_CONFIG_FILE | grep -n '' | grep "${line_num}:" | cut -d= -f2 | awk '{print $1}'`

    echo "FTP_SERVER_IP : $FTP_SERVER_IP"
    echo "FTP_USER      : $FTP_USER"
    echo "FTP_PASSWORD  : $FTP_PASSWORD"
    echo "FTP_PATH      : $FTP_PATH"
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

    if [ ! -d "$OTA_PATH" ]; then
        mkdir -p $OTA_PATH
    fi
    rm -rf $OTA_PATH/*
    sync
}

# --------------------------------------------------------- #
if [ ! -d "$OTA_PATH" ]; then
    mkdir -p $OTA_PATH
fi

get_ftp_configuration

# cancel FTP
for p_pid in `ps -ef | grep "ftp -v -n $FTP_SERVER_IP" | grep -v grep | awk '{print $2}'`
do
    echo "$p_pid"
    kill -9 $p_pid
done

# cancel cp update.img
for p_pid in `ps -ef | grep "cp $UDISK_MOUNT_PATH/update.img" | grep -v grep | awk '{print $2}'`
do
    echo "$p_pid"
    kill -9 $p_pid
done

for p_pid in `ps -ef | grep "adv_update_ota_get_image_background.sh" | grep -v grep | awk '{print $2}'`
do
    echo "$p_pid"
    kill -9 $p_pid
done

for p_pid in `ps -ef | grep "adv_update_ota_get_image.sh" | grep -v grep | awk '{print $2}'`
do
    echo "$p_pid"
    kill -9 $p_pid
done

update_clean
