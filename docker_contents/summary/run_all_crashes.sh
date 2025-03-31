#!/bin/bash

RUN_LIST=$1
CRASHFILE_FOLDER=$2
OUTFILE=$3

if [[ ! -d ${CRASHFILE_FOLDER} ]]; then
    echo "Unable to find folder \"${CRASHFILE_FOLDER}\""
    exit 1
fi

rm ${OUTFILE}

run_list_contents=$(cat ${RUN_LIST})
run_list_arr=(${run_list_contents})
run_list_len=${#run_list_arr[@]}
run_list_sublen=$((run_list_len / 3))

for (( i=0; i<run_list_sublen; i++ )); do
    crashfile_index=$((i * 3))
    bin_index=$((crashfile_index + 2))
    crashfile=${run_list_arr[$crashfile_index]}
    bin=${run_list_arr[$bin_index]}

    full_crashfile="${CRASHFILE_FOLDER}/${crashfile}"
    echo "Running ${full_crashfile} with ${bin}..."
    ./run_crash.sh ${bin} ${full_crashfile} >> ${OUTFILE} 2>&1
done
