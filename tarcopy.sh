#!/bin/bash


if [[ "$1" != "" || "$2" != "" ]]; then
	( cd "$1"; tar cpof - . ) | ( cd "$2"; tar xpof -);
else
	echo "\$1 = src, \$2 = dest"
fi