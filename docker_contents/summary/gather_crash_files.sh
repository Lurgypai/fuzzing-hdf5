#!/bin/bash

FILE_LIST_FILE=$1
FUZZOUT_DIR=$2
OUTPUT_DIR=$3

if [[ ! -e ${FILE_LIST_FILE} ]]; then
	echo "Unable to find file \"${FILE_LIST_FILE}\"..."
	echo "Usage: ./gather_crash_files.sh <file-list-file> <fuzzout-dir> <output-dir>"
	exit
fi

if [[ ! -e ${FUZZOUT_DIR} ]]; then
	echo "Unable to find file \"${FUZZOUT_DIR}\"..."
	echo "Usage: ./gather_crash_files.sh <file-list-file> <fuzzout-dir> <output-dir>"
	exit
fi

mkdir ${OUTPUT_DIR}

FILE_LIST=$(cat ${FILE_LIST_FILE})

for file in ${FILE_LIST}; do
	found=$(find ${FUZZOUT_DIR} -name ${file})
	if [[ ! -z $found ]]; then
		echo "Found target file ${file}, copying..."
		cp $found ${OUTPUT_DIR}
	fi
done

