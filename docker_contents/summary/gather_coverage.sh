hdf5_build="../hdf5_afl"

afl_cov="../afl-cov/afl-cov"
fuzz_dir="../output/fuzzout.small/fuzz_0"
bin="h5dump"

${afl_cov} -d ${fuzz_dir} -e "${hdf5_build}/build.gcc.cov/bin/${bin} AFL_FILE" -c "${hdf5_build}/build.gcc.cov/" --overwrite
