/*##########################################################################
## Function : get update image from ftp or from u-disk, and auto update
## Modify List : 
##     1. First init 2020-09-08 	V1.0.1
##     2. 
##########################################################################*/

#ifndef __LIB_ADV_UPDATE_OTA_H__
#define __LIB_ADV_UPDATE_OTA_H__

//
#define ERR_NO_ERROR                          0
#define ERR_PROCESS_IS_RUNNING               -1
#define ERR_PROJECT_CONFIG                   -2
#define ERR_FTP_CONFIG                       -3
#define ERR_UPDATE_LIST                      -4
#define ERR_VERSION                          -5
#define ERR_DOWNLOAD_IMAGE                   -6
#define ERR_DOWNLOAD_TIMEOUT                 -7

#define ERR_UPDATE_FLOW                      -20

#define ERR_SYSTEM                           -30


int adv_get_download_percent();
int adv_do_update_ota();
void adv_cancel_update_ota();

#endif	/* __LIB_ADV_UPDATE_OTA_H__ */