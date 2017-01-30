#!/bin/bash

Find() {
for SEQ in `seq 0 1000`; do
    CHAR=`dd if="$1" bs=1c count=4 skip=$SEQ 2> /dev/null`
    if [ "$CHAR" = "$STR" ]; then
	echo $SEQ
	break
    fi
done
}

Head() {
NAME="$1"

LEN="`echo $NAME | wc -m`"
NEXT="$NAME"

if [ "$LEN" -lt 16 ]; then
    TO=$((16 - $LEN))
    for X in `seq 0 $TO`; do
	NEXT="${NEXT} "
    done
else
    return 1
fi
printf "$NEXT"
}

if [ "$#" = "0" ]; then
    echo "\$1 - audio file to convert"
    echo "\$2 - the number in name of output file"
    exit 0
fi

if [ "`basename "$1" | cut -d\. -f2`" = "wav" ]; then
    SUFIX=".wav"
    STR="data"
elif [ "`basename "$1" | cut -d\. -f2`" = "aif" ]; then
    STR="SSND"
    SUFIX=".aif"
else
    echo "Unknown suffix"
    exit 1
fi

NAME="`Head "$(basename "$1" $SUFIX)"`"

OFF="`Find "$1"`"

dd if="$1" bs=1c of=tmp skip=$OFF

if [ "`basename "$1" | cut -d. -f2`" = "aif" ]; then

    printf "FORM!��AIFFCOMM!!!!!�|!@�D!!!!!!MARK!!!\"!!!!!!beg.loop!!!�|end.loop!INST!!!<!!!!!!!!!!!!!!APPL!!pRLNDroifxvmc!!!�$NAME!!!!!!!!!�|!�|!!!	!!!!!!!!!!:�!!u�!!��!!�!&�!a|!�f!�P!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!D\\\xvfs!!�!!!!!	!!!!!!!!!!!!!:�!!u�!!��!!�!&�!a|!�f!�P!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!D\!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tr '!' '\0' > header

elif [ "`basename "$1" | cut -d. -f2`" = "wav" ]; then

    printf "RIFF��!!WAVEfmt !!!!!D�!!�!!!RLNDl!!roifxvmc�!!!$NAME!!!!!!!!�.!!�.!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!�*xvfs�!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!�*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tr '!' '\0' > header

else
    exit 1
fi


if [ "`echo $2 | wc -c`" = "2" ]; then
    NAME="000${2}"
elif [ "`echo $2 | wc -c`" = "3" ]; then
    NAME="00${2}"
elif [ "`echo $2 | wc -c`" = "4" ]; then
    NAME="0${2}"
elif [ "`echo $2 | wc -c`" = "5" ]; then
    NAME="${2}"
fi

cat header tmp > smpl${NAME}.aif