#!/bin/bash

echo "NOTE: cloning is disabled to prevent overriding the disabled checksum. Be sure to pull manually for up to date HDF5"

git clone https://github.com/hdfgroup/hdf5 hdf5_afl
pushd hdf5_afl
git checkout develop

BINS="h5dump h5stat h5copy h5repack h5diff"

mkdir build.gcc.cov
pushd build.gcc.cov
cmake \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_C_FLAGS="-fprofile-arcs -ftest-coverage" \
  -DCMAKE_CXX_FLAGS="-fprofile-arcs -ftest-coverage" \
  ..
make -j`nproc`
popd
