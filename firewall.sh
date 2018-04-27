#!/bin/bash

Help() {
	cat <<EOF
Iptables shell firewall wrapper

script that import varibles from /etc/firewall file and create rules from them...

Notation:

1.        2.                  3.        4.                          5.
[inp|fwd]_[Network interface]_[tcp|udp]_[Single port|0x1 Multiport]="Ip addres|List of ip addresses|Cidr Subnet"

1. Iptables chain
2. Name of network interface
3. Port type
4. Number of port or ports range (1024x2000 means from port 1024 to port 2000)
5. Ip addres or CIDR subnet

Example configuration:

OutIfce=""
#      1.  2.   3.  4.   5.
inp_eth0_tcp_80="0.0.0.0/0"
inp_eth0_tcp_1024x2000="0.0.0.0/0"
EOF
}


LoadConfig() {
    buf=""
    while read Line; do
	buf="$buf export ${Line};"
    done < <(grep -v '#' "$1")
    echo "$buf"
}

InputAccept() {
    if [ "`echo "$3" | wc -w`" != 1 ]; then
	for Var in `echo $3`; do
	    iptables -A INPUT -i "$4" -p "$1" --dport "$2" -s "$Var" -j ACCEPT
	done
    else
	iptables -A INPUT -i "$4" -p "$1" --dport "$2" -s "$3" -j ACCEPT
    fi
#	echo "INP - $*"
}

OutputAccept() {
    if [ "`echo "$3" | wc -w`" != 1 ]; then
	for Var in `echo $3`; do
	    iptables -A OUTPUT -o "$4" -p "$1" --sport "$2" -s "$Var" -j ACCEPT
	done
    else
	iptables -A OUTPUT -o "$4" -p "$1" --sport "$2" -s "$3" -j ACCEPT
    fi
#	echo "OUT - $*"
}


Forward() {
    if [ "`echo "$3" | wc -w`" != 1 ]; then
	echo "Not possible!"
    else
	iptables -t nat -A PREROUTING -i "$4" -p "$1" --dport "$2" -j DNAT --to-destination "$3"
    fi
#	echo "FWD - $*"
}

ResetRules() {
	if [ "$1" != "" ]; then
		iptables -t "$1" -F
	else
		TableList="filter nat mangle raw security "
		for Table in `echo $TableList`; do
			iptables -t "$Table" -F
		done
	fi
	iptables -F
}

Conf="$1"

test -e /etc/firewall

if [[ "$1" = "-h" || "$1" = "--help" ]]; then
	Help
	exit 0
fi

if [ "$?" != "0" ]; then
    Vars="`LoadConfig $Conf`"
    eval "$Vars"
else
    Vars="`LoadConfig /etc/firewall`"
    eval "$Vars"
fi

ResetRules

iptables -A INPUT -p icmp -j ACCEPT

iptables -A INPUT -i lo -j ACCEPT

while read Var; do
	Value="`echo $Var | cut -d= -f2`"

	Tmp="`echo $Var | cut -d= -f1`"

	Rule="`echo $Tmp | cut -d_ -f1`"
	Interface="`echo $Tmp | cut -d_ -f2`"
	Type="`echo $Tmp | cut -d_ -f3`"
	Port="`echo $Tmp | cut -d_ -f4`"

	if [ "$Rule" = "inp" ]; then
		if [ "`echo $Port | grep x`" != "" ]; then
			InputAccept "$Type" "`echo $Port | tr x :`" "$Value" "$Interface"
		else
			InputAccept "$Type" "$Port" "$Value" "$Interface"
		fi
	fi
	if [ "$Rule" = "out" ]; then
		if [ "`echo $Port | grep x`" != "" ]; then
			OutputAccept "$Type" "`echo $Port | tr x :`" "$Value" "$Interface"
		else
			OutputAccept "$Type" "$Port" "$Value" "$Interface"
		fi
	fi
	if [ "$Rule" = "fwd" ]; then
		if [ "`echo $Port | grep x`" != "" ]; then
			Forward "$Type" "`echo $Port | tr x :`" "$Value:`echo $Port | tr x -`" "$Interface"
		else
			Forward "$Type" "$Port" "$Value:${Port}" "$Interface"
		fi

	fi
done < <(env | grep -E "udp|tcp")

iptables -A INPUT -i "$OutIfce" -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i "$OutIfce" -j REJECT

exit 0
