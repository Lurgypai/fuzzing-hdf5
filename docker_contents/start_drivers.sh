#!/bin/bash

if [[ -z $AFL_PATH ]]; then
    echo "AFL_PATH is not set, did you source the environment?"
    exit
fi

# Output directory is a command-line parameter
OUTPUT=$1
INPUT="models"

if [ ! $OUTPUT ]; then
  echo "USAGE: ./start <AFL_OUTDIR>"
  exit 1
fi

mkdir $OUTPUT

export AFL_BB_MAP_SIZE=600000

# Directories for the builds
ASAN=./drivers/asan

export LD_LIBRARY_PATH="/workspace/mod_hdf5_out/asan/lib:$LD_LIBRAR_PATH"

afl-fuzz -i $INPUT -o $OUTPUT/read -- ./$ASAN/h5-read-fuzzer > read.log &
READ_PID=$!
afl-fuzz -i $INPUT -o $OUTPUT/extended -- ./$ASAN/h5-extended-fuzzer > extended.log &
EXTENDED_PID=$!
afl-fuzz -i $INPUT -o $OUTPUT/iterate -- ./$ASAN/h5-iterate-fuzzer > iterate.log &
ITERATE_PID=$!
afl-fuzz -i $INPUT -o $OUTPUT/copy -- ./$ASAN/h5-copy-fuzzer > copy.log &
COPY_PID=$!

killall() {
  echo "Exiting.."
  kill $READ_PID
  kill $EXTENDED_PID
  kill $ITERATE_PID
  kill $COPY_PID
  pkill afl-fuzz
  exit 1
}

trap killall SIGINT

while true; do
  clear
  tail -f extended.log
  sleep 60
done
