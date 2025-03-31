#!/usr/bin/bash


target_bin=$1
mode=$2
crash_file=$3

echo "target_bin = $target_bin"
echo "mode = $mode"
echo "crash_file = $crash_file"

hdf5_root=../def_hdf5_out/

#if [ ! -f "$1" ]; then
#  echo "$1 does not exist."
#  exit 1
#fi
if [ ! -e "$crash_file" ]; then
  echo "$crash_file does not exist."
  exit 1
fi

run_on_file () {
    mode=$2
    file=$3

    echo "file = '$file'"

    case $1 in
    h5dump)
    cmd="${hdf5_root}/$mode/bin/h5dump $file"
      ;;

    h5stat)
    cmd="${hdf5_root}/$mode/bin/h5stat -F -g -G -d -D -T -A -s -S $file"
      ;;

    h5copy)
    cmd="${hdf5_root}/$mode/bin/h5copy -i $file -o /dev/null -f allflags -s "/" -d "/outdst" $file"
      ;;

    h5repack)
    cmd="${hdf5_root}/$mode/bin/h5repack $file /dev/null"
      ;;

    h5diff)
    cmd="${hdf5_root}/$mode/bin/h5diff -r -c -v2 $file $file"
      ;;

    *)
    echo "Unknown command: $1"
    exit 1
      ;;
    esac

    echo "cmd = '$cmd'"
    gdb -ex run --args $cmd
}

case $mode in
asan)
    run_on_file $target_bin $mode $crash_file
    ;;
fuzz)
    run_on_file $target_bin $mode $crash_file
    ;;
cmplog)
    run_on_file $target_bin $mode $crash_file
    ;;
raw)
    run_on_file $target_bin $mode $crash_file
    ;;
*)
echo "unknown mode: $mode"
exit 1
    ;;
esac
