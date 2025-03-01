#!/bin/bash

git clone https://github.com/hdfgroup/hdf5 hdf5_afl
pushd hdf5_afl
git checkout develop

BINS="h5dump h5stat h5copy h5repack h5diff"

mkdir build.afl.asan
export AFL_USE_ASAN=1
pushd build.afl.asan
cmake \
  -DCMAKE_C_COMPILER=afl-clang-fast \
  -DCMAKE_C_FLAGS="-g" \
  -DCMAKE_CXX_FLAGS="-g" \
  ..
make -j`nproc` $BINS
unset AFL_USE_ASAN
popd

# Note: MSAN doesn't currently work on MacOS (1/26/24, clang 17.0)
mkdir build.afl.msan
export AFL_USE_MSAN=1
export AFL_MAP_SIZE=300000
export AFL_USE_UBSAN=1
pushd build.afl.msan
cmake \
  -DCMAKE_C_COMPILER=afl-clang-fast \
  -DCMAKE_C_FLAGS="-g" \
  -DCMAKE_CXX_FLAGS="-g" \
  ..
make -j`nproc` $BINS
unset AFL_USE_MSAN
popd

mkdir build.afl.cmplog
export AFL_LLVM_CMPLOG=1
pushd build.afl.cmplog
cmake \
  -DCMAKE_C_COMPILER=afl-clang-fast \
  -DCMAKE_C_FLAGS="-g" \
  -DCMAKE_CXX_FLAGS="-g" \
  ..
make -j`nproc` $BINS
unset AFL_LLVM_CMPLOG
popd


mkdir build.afl.raw
pushd build.afl.raw
cmake \
  -DCMAKE_C_COMPILER=afl-clang-fast \
  -DCMAKE_C_FLAGS="-g" \
  -DCMAKE_CXX_FLAGS="-g" \
  ..
make -j`nproc` $BINS
popd

mkdir build.cov
pushd build.cov
cmake \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_C_FLAGS="-g -fprofile-instr-generate -fcoverage-mapping" \
  -DCMAKE_CXX_FLAGS="-g -fprofile-instr-generate -fcoverage-mapping" \
  ..
make -j`nproc`
popd
