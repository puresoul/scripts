#!/bin/bash

Help() {
	cat <<EOF
Iptables shell firewall wrapper

reads rules from /etc/firewall file and translate them into iptables commands...

Script is reading /etc/hosts.deny and rejecting every ip writen there.

Notation:

1.        2.                  3.        4.                          5.
[inp|fwd]_[Network interface]_[tcp|udp]_[Single port|0x1 Multiport]="Ip addres|List of ip addresses|Cidr Subnet"

1. Iptables chain
2. Name of network interface
3. Port type
4. Number of port or ports range (1024x2000 means from port 1024 to port 2000)
5. Ip addres or CIDR subnet

Example configuration:

# List of interfaces to block traffic on
OutIfce="eth0"
#      1.  2.   3.  4.   5.
inp_eth0_tcp_80="0.0.0.0/0"
inp_eth0_tcp_1024x2000="0.0.0.0/0"
EOF
}

ErrorTest() {
	if [ "$1" != "0" ]; then
		echo "Problem in configuration!"
		exit 0
	fi
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
			ErrorTest "$?"
		done
	else
		iptables -A INPUT -i "$4" -p "$1" --dport "$2" -s "$3" -j ACCEPT
		ErrorTest "$?"
	fi
#	echo "INP - $*"
}

OutputAccept() {
	if [ "`echo "$3" | wc -w`" != 1 ]; then
		for Var in `echo $3`; do
			iptables -A OUTPUT -o "$4" -p "$1" --sport "$2" -s "$Var" -j ACCEPT
			ErrorTest "$?"
		done
	else
		iptables -A OUTPUT -o "$4" -p "$1" --sport "$2" -s "$3" -j ACCEPT
		ErrorTest "$?"
	fi
#	echo "OUT - $*"
}


Forward() {
	if [ "`echo "$3" | wc -w`" != 1 ]; then
		echo "Not possible!"
	else
		iptables -t nat -A PREROUTING -i "$4" -p "$1" --dport "$2" -j DNAT --to-destination "$3"
		ErrorTest "$?"
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

test -e /etc/firewall || echo "No configuration file at /etc/firewall"; exit 1

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
	iptables -A INPUT -i "$OutIfce" -s "$Var" -j REJECT
done < <(grep -v "#" /etc/hosts.deny)

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

for Var in `echo $OutIfce`; do
	iptables -A INPUT -i "$OutIfce" -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A INPUT -i "$OutIfce" -j REJECT
done

exit 0
