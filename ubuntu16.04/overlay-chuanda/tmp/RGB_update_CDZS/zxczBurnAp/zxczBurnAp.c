#include "zxczBurnAp.h"
#include "util.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>
#include <error.h>

void SetProgress(void *ptrClass, float fProcess)
{
	printf("fProcess %5f\n", fProcess);
}

bool BurnerFW()
{
	bool ret = false;
	char buffer[300];
	char *p = getcwd(buffer, 40);
	char *dir = (char*)get_current_dir_name();
	char fileName[100];
	
	printf("\nstart burning fw\n");
	memset(fileName, 0, 100);
	sprintf(fileName, "%s/%s", dir, "5256-ARCDZS-R-V200113_C0_01-ZXCZ_LHT.src"); 
	//sprintf(fileName, "%s/%s", dir, "5256-AR0230-R-V200814_K0_05-CDZS_LHT.src"); 

	FILE *fileHandle;
	if(!(fileHandle = fopen(fileName, "rb")))
	{
		printf("open file fail\n");
		return false;
	}
	struct stat fileInfo;
	stat(fileName, &fileInfo);
	char *pFW = malloc(fileInfo.st_size + 1);
	printf("fileInfo.st_size = %x\n", (unsigned int)fileInfo.st_size);
	fread(pFW, 1, fileInfo.st_size, fileHandle);
	fclose(fileHandle);
	
	printf("NOTE: start burner fw, not to openrate camera.\n");
	printf("NOTE: wait burn finish.\n");
	ret = SonixCam_BurnerFW(pFW, fileInfo.st_size, SetProgress, 0, SFT_ST, FALSE);
	if(ret)
		printf("\nNOTE: burner fw success, please reboot device.\n");
	else
		printf("\nWARN: burner fw fail.\n");

	free(pFW);
	pFW = 0;

	return ret;
}

void BurnerSN()
{
	ChangeParamInfo cp;
	memset(&cp, 0x0, sizeof(cp));

	BYTE vidpid[5] = {0};
	vidpid[0] = 0x0c;
	vidpid[1] = 0x45;
	vidpid[2] = 0x33;
	vidpid[3] = 0x44;
	cp.pVidPid = vidpid;
	cp.pSerialNumber = "SN000100001";
	cp.SerialNumberLength = 11;

	char buffer[300];
	char *p = getcwd(buffer, 40);
	char *dir = (char*)get_current_dir_name();
	char fileName[100];
	memset(fileName, 0, 100);
	sprintf(fileName, "%s/%s", dir, "292B-AR0230---V200319_ZZ_03-ZXCZ_HJGX.src"); 

	FILE *fileHandle;
	if(!(fileHandle = fopen(fileName, "rb")))
	{
		printf("open file fail\n");
		return;
	}
	struct stat fileInfo;
	stat(fileName, &fileInfo);
	char *pFW = malloc(fileInfo.st_size + 1);
	printf("fileInfo.st_size = %x\n", (unsigned int)fileInfo.st_size);
	fread(pFW, 1, fileInfo.st_size, fileHandle);
	fclose(fileHandle);

	SonixCam_SetParamTableFormFWFile(pFW, fileInfo.st_size, &cp, NULL, NULL, SFT_MXIC, NULL);

}


#define FLASH_RW_TEST 0
#define SECTOR_LEN 4096
#define START_ADDR 0x30000
#define END_ADDR 0x40000
int main(int argc, char *argv[])
{
	int i = 0;
	bool ret = false;

    for (i=0; i < argc; i++)
        printf("Argument %d is %s.\n", i, argv[i]);
	
	char *vidpid = "0c456367"; //0c459282 0c452375 0c456362 0c456366 2bc50620 2bc50520 32a80338 0bda0230
	fprintf(stderr, "open sonix default device 0c456367\n");
	if(TRUE != SonixCam_Init(vidpid)){
		fprintf(stderr, "Could not find/open sonix device 0c456367\n");
		//exit(1);
		
		fprintf(stderr, "open sonix default device 0c456362\n");
		//strcpy(vidpid,"0c456362")
		vidpid = "0c456362";
		if(TRUE != SonixCam_Init(vidpid)){
			fprintf(stderr, "Could not find/open sonix device 0c456362\n");
			exit(1);
		}
	} 
	
	fprintf(stderr, "find device\n");

	//get fw version
	unsigned char pFwVer[100] = {0};
        long          len         = 100;
	SonixCam_GetFwVersion(pFwVer, len, false);
	printf("Get fw version: %s\n", pFwVer);

	//burner fw
	printf("Burner FW:\n");
	BurnerFW();

	SonixCam_UnInit();
	return 1;
}

