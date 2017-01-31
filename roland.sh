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

DIR="$1"

NUM=0

while read FILE; do

let NUM=NUM+1

printf "$FILE"

if [ "`echo "$FILE" | sed 's/$*.*\\.//'`" = "wav" ]; then
    SUFIX=".wav"
    STR="data"
elif [ "`echo "$FILE" | sed 's/$*.*\\.//'`" = "aif" ]; then
    STR="SSND"
    SUFIX=".aif"
else
    printf " has Unknown suffix\n"
    continue
fi

if [ "`echo $NUM | wc -c`" = "2" ]; then
    FILENAME="000${NUM}"
elif [ "`echo $NUM | wc -c`" = "3" ]; then
    FILENAME="00${NUM}"
elif [ "`echo $NUM | wc -c`" = "4" ]; then
    FILENAME="0${NUM}"
elif [ "`echo $NUM | wc -c`" = "5" ]; then
    FILENAME="${NUM}"
fi

if [ -f "smpl${FILENAME}.aif" ]; then
    printf " skiped!\n"
    exit 0
else
    printf " procesing,"
fi

NAME="`Head "$(basename "$" $SUFIX)"`"

OFF="`Find "$FILE"`"

dd if="$FILE" bs=1c of=tmp skip=$OFF 2> /dev/null

if [ "$SUFIX" = ".aif" ]; then

    printf "FORM!ÛäAIFFCOMM!!!!!ì|!@¬D!!!!!!MARK!!!\"!!!!!!beg.loop!!!ì|end.loop!INST!!!<!!!!!!!!!!!!!!APPL!!pRLNDroifxvmc!!!¸$NAME!!!!!!!!!ì|!ì|!!!	!!!!!!!!!!:ê!!uÔ!!°¾!!ë¨!&’!a|!œf!×P!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!D\\\xvfs!! !!!!!	!!!!!!!!!!!!!:ê!!uÔ!!°¾!!ë¨!&’!a|!œf!×P!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!D\!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tr '!' '\0' > header

elif [ "$SUFIX" = ".wav" ]; then

    printf "RIFFˆ¾!!WAVEfmt !!!!!D¬!!±!!!RLNDl!!roifxvmc¸!!!$NAME!!!!!!!!ü.!!ü.!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!ø*xvfs !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!ø*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tr '!' '\0' > header

else
    continue
fi

cat header tmp > smpl${FILENAME}.aif

printf " Done!\n"

done < <(find "$1" -type f)