#!/bin/bash

. env.sh

if [[ -e /tmp/bb_record ]]; then
    echo "bb_record for modified AFLplusplus exists, removing..."
    rm /tmp/bb_record
fi

mkdir def_hdf5_out

git clone https://github.com/hdfgroup/hdf5 hdf5_afl
pushd hdf5_afl
git checkout develop
git status
git rev-parse --short HEAD

BINS="h5dump h5stat h5copy h5repack h5diff"

mkdir build.afl.asan
export AFL_USE_ASAN=1
pushd build.afl.asan
cmake \
  -DCMAKE_C_COMPILER=afl-clang-fast \
  -DCMAKE_C_FLAGS="-g" \
  -DCMAKE_CXX_FLAGS="-g" \
  -DCMAKE_INSTALL_PREFIX="/workspace/def_hdf5_out/asan" \
  -DHDF5_ENABLE_ASSERTS=Off \
  ..
make $BINS -j`nproc` && make install
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
  -DCMAKE_INSTALL_PREFIX="/workspace/def_hdf5_out/msan" \
  -DHDF5_ENABLE_ASSERTS=Off \
  ..
make $BINS -j`nproc` && make install
unset AFL_USE_MSAN
popd

mkdir build.afl.cmplog
export AFL_LLVM_CMPLOG=1
pushd build.afl.cmplog
cmake \
  -DCMAKE_C_COMPILER=afl-clang-fast \
  -DCMAKE_C_FLAGS="-g" \
  -DCMAKE_CXX_FLAGS="-g" \
  -DCMAKE_INSTALL_PREFIX="/workspace/def_hdf5_out/cmplog" \
  -DHDF5_ENABLE_ASSERTS=Off \
  ..
make $BINS -j`nproc` && make install
unset AFL_LLVM_CMPLOG
popd


mkdir build.afl.raw
pushd build.afl.raw
cmake \
  -DCMAKE_C_COMPILER=afl-clang-fast \
  -DCMAKE_C_FLAGS="-g" \
  -DCMAKE_CXX_FLAGS="-g" \
  -DCMAKE_INSTALL_PREFIX="/workspace/def_hdf5_out/raw" \
  -DHDF5_ENABLE_ASSERTS=Off \
  ..
make $BINS -j`nproc` && make install
popd

mkdir build.gcc.cov
pushd build.gcc.cov
cmake \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_C_FLAGS="-fprofile-arcs -ftest-coverage" \
  -DCMAKE_CXX_FLAGS="-fprofile-arcs -ftest-coverage" \
  -DCMAKE_INSTALL_PREFIX="/workspace/def_hdf5_out/cov" \
  -DHDF5_ENABLE_ASSERTS=Off \
  ..
make $BINS -j`nproc` && make install
popd

mkdir build.gcc
pushd build.gcc
cmake \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_INSTALL_PREFIX="/workspace/def_hdf5_out/gcc" \
  -DHDF5_ENABLE_ASSERTS=Off \
  ..
make $BINS -j`nproc` && make install
popd
