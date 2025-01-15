#!/usr/bin/bash

echo "targetbin = $1"
echo "in_dir = $2"
echo "out_dir = $3"

hdf5_root=hdf5_afl

#if [ ! -f "$1" ]; then
#  echo "$1 does not exist."
#  exit 1
#fi
if [ ! -d "$2" ]; then
  echo "$2 does not exist."
  exit 1
fi
if [ ! -d "$3" ]; then
  echo "$3 does not exist, creating it."
  mkdir $3
fi

for mode in asan fuzz cmplog raw; do
  for file in $2/id*; do
    if [ -f "$file" ]; then
      echo "file = '$file'"

      case $1 in
        h5dump)
  	  cmd="${hdf5_root}/build.afl.$mode/bin/h5dump $file"
          ;;

        h5stat)
  	  cmd="${hdf5_root}/build.afl.$mode/bin/h5stat -F -g -G -d -D -T -A -s -S $file"
          ;;

        h5copy)
  	  cmd="${hdf5_root}/build.afl.$mode/bin/h5copy -i $file -o /dev/null -f allflags -s "/" -d "/outdst" $file"
          ;;

        h5repack)
  	  cmd="${hdf5_root}/build.afl.$mode/bin/h5repack $file /dev/null"
          ;;

        h5diff)
  	  cmd="${hdf5_root}/build.afl.$mode/bin/h5diff -r -c -v2 $file $file"
          ;;

        *)
  	  echo "Unknown command: $1"
	  exit 1
          ;;
      esac

      echo "cmd = '$cmd'"
      bn=$(basename $file)
      gdb -batch -ex "set backtrace limit 400" -ex "set logging overwrite on" -ex "set logging enabled on" -ex run -ex "bt full" -ex quit --args $cmd  2> $3/$bn.$mode.stderr
      mv gdb.txt $3/$bn.$mode
    fi
  done
done

