#!/bin/bash

Help() {
	cat <<EOF
Iptable shell firewall wrapper

script that import varibles from /etc/firewall file and create rules from them...

Notation:

[inp|fwd]_[Network interface]_[tcp|udp]_[Single port|0x1 Multiport]="Ip addres|List of ip addresses|Cidr Subnet"

Example:

export inp_eth0_tcp_3306="81.0.213.147"
export inp_eth0_tcp_22="90.176.62.151 217.16.185.211"
export inp_eth0_tcp_80="90.176.62.151 217.16.185.211"
export inp_eth0_tcp_1234="0.0.0.0/0"

EOF
}

Conf="$1"

test -e /etc/firewall

if [[ "$1" = "-h" || "$1" = "--help" ]]; then
	Help
	exit 0
fi

if [ "$?" != "0" ]; then
    . $Conf
else
    . /etc/firewall
fi

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

Forward() {
    if [ "`echo "$3" | wc -w`" != 1 ]; then
	for Var in `echo $3`; do
	    iptables -t nat -A PREROUTING -i "$4" -p "$1" --dport "$2" -j DNAT --to-destination "$Var"
	done
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
	if [ "$Rule" = "fwd" ]; then
		if [ "`echo $Port | grep x`" != "" ]; then
			Forward "$Type" "`echo $Port | tr x :`" "$Value" "$Interface"
		else
			Forward "$Type" "$Port" "$Value" "$Interface"
		fi

	fi
done < <(env | grep -E "udp|tcp")

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -j REJECT

exit 0
