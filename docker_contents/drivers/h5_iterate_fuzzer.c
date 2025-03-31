#include "hdf5.h"

#include <unistd.h>

#include <string.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdint.h>

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

herr_t
op_func(hid_t loc_id, const char *name, const H5L_info_t *info, void *operator_data)
{
    herr_t     status;
    H5O_info_t infobuf;

    /*
     * Get type of the object and display its name and type.
     * The name of the object is passed to this function by
     * the Library.
     */
#if H5_VERSION_GE(1, 12, 0) && !defined(H5_USE_110_API) && !defined(H5_USE_18_API) && !defined(H5_USE_16_API)
    status = H5Oget_info_by_name(loc_id, name, &infobuf, H5O_INFO_ALL, H5P_DEFAULT);
#else
    status = H5Oget_info_by_name(loc_id, name, &infobuf, H5P_DEFAULT);
#endif
    switch (infobuf.type) {
        case H5O_TYPE_GROUP:
            printf("  Group: %s\n", name);
            break;
        case H5O_TYPE_DATASET:
            printf("  Dataset: %s\n", name);
            break;
        case H5O_TYPE_NAMED_DATATYPE:
            printf("  Datatype: %s\n", name);
            break;
        default:
            printf("  Unknown: %s\n", name);
    }

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

    hid_t file = H5Fopen(filename, H5F_ACC_RDWR, H5P_DEFAULT);
    if (file < 0) return 0; // not a useful error, just skip
    herr_t status = H5Literate(file, H5_INDEX_NAME, H5_ITER_NATIVE, NULL, op_func, NULL);
    if(status < 0) return 0; // not a useful error;
    status = H5Fclose(file);
    return 0;
}
