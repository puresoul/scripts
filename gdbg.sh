#!/bin/bash

if [ "$1" != "" ]; then
	echo "write some PID!"
	exit 1
fi

gdb -q -ex 'call close(1)' -ex 'call open("output.txt", 01102, 0600)' -ex detach -ex quit -p "$1"