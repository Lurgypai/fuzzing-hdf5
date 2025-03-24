#!/bin/bash

OUT_DIR=$2
FUZZ_DIR=$1

if [[ ! -e ${FUZZ_DIR} ]]; then
	echo "Unable to find directory \"${FUZZ_DIR}\""
	echo "Usage: ./generate_full_report.sh <fuzz-output-dir> <output-dir>"
	exit
fi

if [[ ! -e ${OUT_DIR} ]]; then
	echo "Genertaing output directory \"${OUT_DIR}\"..."
	mkdir ${OUT_DIR}
else
	echo "WARNING: Output directory \"${OUT_DIR}\" exists."
fi

reports_dir="${OUT_DIR}/reports"
summary_dir="${OUT_DIR}/summary"

echo "Gathering crashes into reports dir..."
./gather_crashes.sh ${FUZZ_DIR} ${reports_dir}

echo "Generating full summary from reports..."
./full_crash_summary.py ${reports_dir} ${summary_dir}

echo "Gathering READ crashes..."
./gather_crash_files.sh "${summary_dir}/reverse/read/list.txt" ${FUZZ_DIR} "${OUT_DIR}/read_crashes"

echo "Gathering WRITE crashes..."
./gather_crash_files.sh "${summary_dir}/reverse/write/list.txt" ${FUZZ_DIR} "${OUT_DIR}/write_crashes"
