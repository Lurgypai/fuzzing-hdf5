#include "hdf5.h"

#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <fcntl.h>

static int FindOrAddSig(int fd) {
    const char sig[8] = {137, 72, 68, 70, 13, 10, 26, 10};
    int len = lseek(fd, 0, SEEK_END);
    if(len < 0) return -1;

    char buf[8];
    int pos = 0;
    while(pos < len) {
        if(lseek(fd, pos, SEEK_SET) < 0) return -1;
        if(read(fd, buf, 8) < 0) return -1;
        // found sig, exit
        if(strcmp(buf, sig) == 0) return 0;
        pos += 512;
    }

    //no sig found, insert at front
    if(lseek(fd, 0, SEEK_SET) < 0) return -1;
    write(fd, sig, 8);
    return 0;
}

extern int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    char filename[256];
    sprintf(filename, "/tmp/libfuzzer.%d", getpid());

    FILE *fp = fopen(filename, "wb");
    if (!fp) {
        return 0;
    }
    fwrite(data, size, 1, fp);
    fclose(fp);

    int fid = open(filename, O_RDWR | O_CREAT, 0644);
    if(FindOrAddSig(fid) < 0) return 0;
    close(fid);

    hid_t sourceFile = H5Fopen(filename, H5F_ACC_RDWR, H5P_DEFAULT);
    if(sourceFile < 0) return 0;
    
    //h5repack @@ /dev/null
    //tools/src/h5repack/h5repack_copy.c:copy_objects

    return 0;
}
