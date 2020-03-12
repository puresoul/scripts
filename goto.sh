#!/bin/bash

# BAT / CMD goto function
goto()
{
    label=($*)
    if [[ "${label[0]}" == "end" ]]; then
	cmd=$(sed "/^:[[:blank:]]*${label[1]}/,/^:[[:blank:]]*${label[*]}/!d" $0)
    else
	cmd=$(sed -n "/^:[[:blank:]]*${label[0]}/{:a;n;p;ba};" $0)
    fi
    echo $cmd
    eval "$cmd"
    exit
}

# Just for the heck of it: how to call where to jump to ("b" would go from ": b" and "end b" wold go form ": b" to ": end b"):
if [ "$1" != "" ]; then
    goto "$*"
fi

: a
goto_msg="a"
echo $goto_msg
: end a

: b
goto_msg="b"
echo "$goto_msg"
: end b

: c
goto_msg="c"
echo "$goto_msg"
: end c