#!/bin/bash

# user to connect

USER="adams"

# ssh-key to use

KEY="./id_rsa"

# server list

OUTLIST=""
INLIST=""
ALLLIST="$OUTLIST $INLIST"

# simple heredoc file hack what we run with sudo

CreateCommand() {
cat > ./cmd <<EOF
#!/bin/bash
`echo $1`
EOF
chmod 777 ./cmd
}

if [[ "$1" == ""  || "$1" == "-h" || "$1" == "--help" ]]; then
    echo "If sudo has nopasswd setup"
    echo "./$0 'command'"
    echo "to scp file over user home"
    echo "./$0 'command' 'file'"
    echo "or"
    echo "If sudo needs user password"
    echo "./$0 'command' 'sudo pass'"
    echo "to scp file over user home"
    echo "./$0 'command' 'file' 'sudo pass'"
    exit 0
else
    CreateCommand "$1"
    for SERVER in $(echo $ALLLIST); do
	if [ "$2" = "-q" ]; then
	    scp -i $KEY ./cmd $USER@$SERVER:/tmp/cmd &> /dev/null
	    ssh -t -i $KEY $USER@$SERVER "sudo -S /tmp/cmd" 2>&1
	    ssh -t -i $KEY $USER@$SERVER "rm /tmp/cmd" &> /dev/null
	elif [ -f "$2" ]; then
	    if [ "$3" != "" ]; then
		scp -i $KEY ./"$2" $USER@$SERVER:~/ &> /dev/null
		scp -i $KEY ./cmd $USER@$SERVER:/tmp/cmd &> /dev/null
		ssh -t -i $KEY $USER@$SERVER "sudo -S /tmp/cmd <<< '$2'" 2>&1
		ssh -t -i $KEY $USER@$SERVER "rm /tmp/cmd" &> /dev/null
	    else
		scp -i $KEY ./"$2" $USER@$SERVER:~/ &> /dev/null
		scp -i $KEY ./cmd $USER@$SERVER:/tmp/cmd &> /dev/null
	        ssh -t -i $KEY $USER@$SERVER "sudo -S /tmp/cmd" 2>&1
	        ssh -t -i $KEY $USER@$SERVER "rm /tmp/cmd" &> /dev/null
	    fi
	elif [ "$2" != "" ]; then
	    printf "COMMAND FOR SERVER $SERVER:\n\n"
	    scp -i $KEY ./cmd $USER@$SERVER:/tmp/cmd &> /dev/null
	    ssh -t -i $KEY $USER@$SERVER "sudo -S /tmp/cmd <<< '$2'" 2>&1
	    ssh -t -i $KEY $USER@$SERVER "rm /tmp/cmd" &> /dev/null
	else
	    printf "COMMAND FOR SERVER $SERVER:\n\n"
	    scp -i $KEY ./cmd $USER@$SERVER:/tmp/cmd &> /dev/null
	    ssh -t -i $KEY $USER@$SERVER "sudo -S /tmp/cmd" 2>&1
	    ssh -t -i $KEY $USER@$SERVER "rm /tmp/cmd" &> /dev/null
	fi
    done
fi