#!/bin/bash

rg --no-filename SUMMARY reports | sort | uniq -c
