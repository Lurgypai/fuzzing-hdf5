afl_cov="../afl-cov/afl-cov"
fuzz_dir="fuzzout.small/fuzz_8"
bin="h5copy"

${afl_cov} -d ${fuzz_dir} -e "./hdf5_afl/build.gcc.cov/bin/${bin} AFL_FILE" -c ./hdf5_afl/build.gcc.cov/ --overwrite
