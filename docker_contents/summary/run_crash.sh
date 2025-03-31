#!/usr/bin/bash


target_bin=$1
crash_file=$2

echo "target_bin = $target_bin"
echo "crash_file = $crash_file"

hdf5_root=../def_hdf5_out/

if [ ! -e "$crash_file" ]; then
  echo "$crash_file does not exist."
  exit 1
fi

case ${target_bin} in
h5dump)
cmd="${hdf5_root}/gcc/bin/h5dump $crash_file"
  ;;

h5stat)
cmd="${hdf5_root}/gcc/bin/h5stat -F -g -G -d -D -T -A -s -S $crash_file"
  ;;

h5copy)
cmd="${hdf5_root}/gcc/bin/h5copy -i $crash_file -o /dev/null -f allflags -s "/" -d "/outdst" $crash_file"
  ;;

h5repack)
cmd="${hdf5_root}/gcc/bin/h5repack $crash_file /dev/null"
  ;;

h5diff)
cmd="${hdf5_root}/gcc/bin/h5diff -r -c -v2 $crash_file $crash_file"
  ;;

*)
echo "Unknown command: $1"
exit 1
  ;;
esac

echo "cmd = '$cmd'"
gdb -ex run --batch --args $cmd

