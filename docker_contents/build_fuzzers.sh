#!/bin/bash 

#output to save make logs to
OUTPUT_DIR=output

pushd drivers > /dev/null

rm -r asan
mkdir asan
export AFL_USE_ASAN=1

afl-clang-fast \
       	-I"/workspace/hdf5_out/asan/include" \
	-L"/workspace/AFLplusplus/" -lAFLDriver \
	-L"/workspace/hdf5_out/asan/lib" -lhdf5 \
	h5_read_fuzzer.c -o h5-read-fuzzer \
    &> asan-read-fuzzer.log

afl-clang-fast \
       	-I"/workspace/hdf5_out/asan/include" \
	-L"/workspace/AFLplusplus/" -lAFLDriver \
	-L"/workspace/hdf5_out/asan/lib" -lhdf5 \
	h5_extended_fuzzer.c -o h5-extended-fuzzer \
    &> asan-extended-fuzzer.log

mv h5-read-fuzzer asan
mv h5-extended-fuzzer asan

popd > /dev/null

# move logs to output so they don't get lost
mv drivers/asan-read-fuzzer.log ${OUTPUT_DIR}/
mv drivers/asan-extended-fuzzer.log ${OUTPUT_DIR}/
