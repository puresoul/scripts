#!/bin/bash

# BAT / CMD goto function
goto()
{
    label=$1
    if [[ "$2" == "end" ]]; then
	cmd=$(sed "/^: *${label}/,/^: end *${label}/!d" $0)
    else
	cmd=$(sed -n "/^:[[:blank:]][[:blank:]]*${label}/{:a;n;p;ba};" $0)
    fi
    eval "$cmd"
    exit
}

# Just for the heck of it: how to create a variable where to jump to:
if [ "$1" != "" ]; then
    goto "${1:-"$1"}" $2
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