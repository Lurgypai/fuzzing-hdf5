#!/bin/bash

out_dir="plots"

fuzz_root_dir="fuzzout.small"
target_bins=('h5dump' 'h5stat' 'h5copy' 'h5repack' 'h5diff')
threads_per_fuzz=4

rm -r ${out_dir}
mkdir ${out_dir}


curr_thread=0
for dir in ${fuzz_root_dir}/*; do
    i=$((${curr_thread} / ${threads_per_fuzz}))

    name="${target_bins[${i}]}.fuzz_${curr_thread}.plot"
    echo "Generating ${name}..."
    afl-plot ${dir} ${out_dir}/${name}

    curr_thread=$((${curr_thread} + 1))
done
