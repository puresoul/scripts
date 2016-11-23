#!/bin/bash

# Uzivatel pod kterym je klic

USER="user"

# Cesta k klici

KEY="./id_rsa"

# Seznam serveru

LIST="s1 s2 s3"

# Overeni ze byl zadan prikaz

if [ "$1" == "" ]; then
    echo "\$0 \"command\" \$1 sudo pass"
    echo "or"
    echo "\$0 \"-\" \"command\" \$1 sudo pass"
    exit
else

    for SERVER in $(echo $LIST); do
	if [ "$1" = "-" ]; then
	    ssh -t -i $KEY $USER@$SERVER "echo '#!/bin/bash' > /tmp/cmd; echo \"$2\" >> /tmp/cmd; chmod 777 /tmp/cmd"
	    ssh -t -i $KEY $USER@$SERVER "sudo -S /tmp/cmd <<< '$3'"
	    ssh -t -i $KEY $USER@$SERVER "rm /tmp/cmd"
	else
	    printf "COMMAND FOR SERVER $SERVER:\n\n"
	    ssh -t -i $KEY $USER@$SERVER "sudo -S $1 <<< \"$2\""
	    printf "\n\nDISCONECT FROM $SERVER\n"
	fi
	read ANY; test "$ANY" && clear
    done

fi
