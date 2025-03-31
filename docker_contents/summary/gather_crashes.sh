#!/bin/bash

OUTDIR=$1
HDF5_DIR=../def_hdf5_out
REPORTS_DIR=$2

if [ ! $OUTDIR ]; then
  echo "USAGE: ./gather_crashes <AFL_OUTDIR>"
  exit 1
fi

# Make the reports dir
mkdir ${REPORTS_DIR} 2>/dev/null || true

# Execute all crashes with all binaries using all sanitizers
for mode in asan fuzz cmplog raw; do
  for f in $(fdfind id $OUTDIR | rg crash); do 
    # If this file has already been cached, ignore it
    REPORT_FILE=${REPORTS_DIR}/`basename $f`.$mode
    if [ -f $REPORT_FILE.h5dump ]; then
      continue
    fi
   
    # Execute the current tool and gather its report
    timeout 10 $HDF5_DIR/$mode/bin/h5dump $f 1>/dev/null 2>$REPORT_FILE.h5dump
    timeout 10 $HDF5_DIR/$mode/bin/h5stat -F -g -G -d -D -T -A -s -S $f 1>/dev/null 2>$REPORT_FILE.h5stat
    timeout 10 $HDF5_DIR/$mode/bin/h5repack $f /dev/null 1>/dev/null 2>$REPORT_FILE.h5repack
  done
done

rm core*

# Look for any bugs
# rg --no-filename SUMMARY reports | sort | uniq -c
