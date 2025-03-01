#!/bin/bash

# Output directory is a command-line parameter
OUTPUT=$1

if [ ! $OUTPUT ]; then
  echo "USAGE: ./start <AFL_OUTDIR>"
  exit 1
fi

# If this is a fresh start, use the models as an input corpus, otherwise, use "-" 
# to signal to afl to resume from the current state
if [ -e $OUTPUT ]; then
  INPUT="-"
else 
  INPUT="models"
fi

# Directories for the builds
ASAN=./hdf5_afl/build.afl.asan/
FUZZ=./hdf5_afl/build.afl.msan/
CMPLOG=./hdf5_afl/build.afl.cmplog/
RAW=./hdf5_afl/build.afl.raw/

# Wants more than the default 1000ms timeout value, so pass -t parameter
python3 launch.py \
  -i $INPUT \
  -o $OUTPUT \
  -c 4 \
  -t 1500 \
  --asan $ASAN/bin/h5dump \
  --ubsan $FUZZ/bin/h5dump \
  --cmplog $CMPLOG/bin/h5dump \
  --nocmplog $RAW/bin/h5dump \
  -- @@ \
  > h5dump.log \
  & \
  # END
DUMP_PID=$!
sleep 15

python3 launch.py \
  -i $INPUT  \
  -o $OUTPUT \
  -c 4 \
  --asan $ASAN/bin/h5stat \
  --ubsan $FUZZ/bin/h5stat \
  --cmplog $CMPLOG/bin/h5stat \
  --nocmplog $RAW/bin/h5stat \
  -- -F -g -G -d -D -T -A -s -S @@ \
  > h5stat.log \
  & \
  # END
STAT_PID=$!
sleep 15

python3 launch.py \
  -i $INPUT \
  -o $OUTPUT \
  -c 4 \
  --asan $ASAN/bin/h5copy \
  --ubsan $FUZZ/bin/h5copy \
  --cmplog $CMPLOG/bin/h5copy \
  --nocmplog $RAW/bin/h5copy \
  -- -i @@ -o /dev/null -f allflags -s / -d /dstout \
  > h5copy.log \
  & \
  # END
COPY_PID=$!
sleep 15

python3 launch.py \
  -i $INPUT \
  -o $OUTPUT \
  -c 4 \
  --asan $ASAN/bin/h5repack \
  --ubsan $FUZZ/bin/h5repack \
  --cmplog $CMPLOG/bin/h5repack \
  --nocmplog $RAW/bin/h5repack \
  -- @@ /dev/null \
  > h5repack.log \
  & \
  # END
REPACK_PID=$!
sleep 15

python3 launch.py \
  -i $INPUT \
  -o $OUTPUT \
  -c 4 \
  --asan $ASAN/bin/h5diff \
  --ubsan $FUZZ/bin/h5diff \
  --cmplog $CMPLOG/bin/h5diff \
  --nocmplog $RAW/bin/h5diff \
  -- -r -c -v2 @@ @@ \
  > h5diff.log \
  & \
  # END
DIFF_PID=$!

killall() {
  echo "Exiting.."
  kill $DUMP_PID
  kill $STAT_PID
  kill $COPY_PID
  kill $REPACK_PID
  kill $DIFF_PID
  pkill afl-fuzz
  exit 1
}

trap killall SIGINT

while true; do
  clear
  tail -f h5diff.log
  sleep 60
done
