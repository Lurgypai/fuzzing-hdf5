#!/bin/bash

OUTDIR=$1

if [ ! $OUTDIR ]; then
  echo "USAGE: ./gather_crashes <AFL_OUTDIR>"
  exit 1
fi

# Make the reports dir
mkdir reports 2>/dev/null || true

# Execute all crashes with all binaries using all sanitizers
for mode in asan fuzz cmplog raw; do
  for f in $(fdfind id $OUTDIR | rg crash); do 
    # If this file has already been cached, ignore it
    REPORT_FILE=reports/`basename $f`.$mode
    if [ -f $REPORT_FILE.h5dump ]; then
      continue
    fi
   
    # Execute the current tool and gather its report
    hdf5_afl/build.afl.$mode/bin/h5dump $f 1>/dev/null 2>$REPORT_FILE.h5dump
    hdf5_afl/build.afl.$mode/bin/h5stat -F -g -G -d -D -T -A -s -S $f 1>/dev/null 2>$REPORT_FILE.h5stat
#    ../build_$mode/hdf5/bin/h5copy -i $f -o /dev/null -f allflags -s "/" -d "/outdst" $f 2>$REPORT_FILE.h5copy
    hdf5_afl/build.afl.$mode/bin/h5repack $f /dev/null 1>/dev/null 2>$REPORT_FILE.h5repack
  done
done

# Look for any bugs
rg --no-filename SUMMARY reports | sort | uniq -c
