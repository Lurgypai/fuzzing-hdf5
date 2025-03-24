#!/bin/bash

if [[ ! -e $1 ]]; then
    echo "Unable to find directory \"$1\", usage: ./summarize_crashes.sh <folder_name>"
    exit
fi

rg --no-filename SUMMARY $1 | sort | uniq -c
