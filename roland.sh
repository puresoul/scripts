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

#
# Start
#

if [ "$#" = "0" ]; then
    echo "\$1 - Path to directory where samples to convert is located"
    echo "example: script is at same place with \"samples\" directory"
    echo " ./roland.sh ./samples"
    exit 0
fi

#
# Directory where to find samples
#

DIR="$1"

#
# Temp variable to make output file name
#

NUM=1

#
# Main cycle loop
#

while read FILE; do

    printf "$FILE"

    #
    # Check for suffix and set data for header
    #

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

    #
    # Make number for output file name
    #

    if [ "`echo $NUM | wc -c`" = "2" ]; then
	FILENAME="000${NUM}"
    elif [ "`echo $NUM | wc -c`" = "3" ]; then
	FILENAME="00${NUM}"
    elif [ "`echo $NUM | wc -c`" = "4" ]; then
	FILENAME="0${NUM}"
    elif [ "`echo $NUM | wc -c`" = "5" ]; then
	FILENAME="${NUM}"
    fi

    #
    # When runing over partialy converted set of files, it skips if file exists
    #

    if [ -f "smpl${FILENAME}.aif" ]; then
	printf " skiped!\n"
	continue
    else
	printf " procesing,"
    fi

    #
    # Proces the original filename into new header, than truncate old header
    #

    NAME="`Head "$(basename "$" $SUFIX)"`"
    OFF="`Find "$FILE"`"

    dd if="$FILE" bs=1c of=tmp skip=$OFF 2> /dev/null

    if [ "$SUFIX" = ".aif" ]; then
	printf "FORM!ÛäAIFFCOMM!!!!!ì|!@¬D!!!!!!MARK!!!\"!!!!!!beg.loop!!!ì|end.loop!INST!!!<!!!!!!!!!!!!!!APPL!!pRLNDroifxvmc!!!¸$NAME!!!!!!!!!ì|!ì|!!!	!!!!!!!!!!:ê!!uÔ!!°¾!!ë¨!&’!a|!œf!×P!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!D\\\xvfs!! !!!!!	!!!!!!!!!!!!!:ê!!uÔ!!°¾!!ë¨!&’!a|!œf!×P!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!D\!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tr '!' '\0' > header
    elif [ "$SUFIX" = ".wav" ]; then
	printf "RIFFˆ¾!!WAVEfmt !!!!!D¬!!±!!!RLNDl!!roifxvmc¸!!!$NAME!!!!!!!!ü.!!ü.!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!ø*xvfs !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!<!ø*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" | tr '!' '\0' > header
    fi

    #
    # Concate new header with truncate file
    #

    cat header tmp > smpl${FILENAME}.aif

    printf " Done!\n"

    let NUM=NUM+1

done < <(find "$1" -type f)

rm header tmp
