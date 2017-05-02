#!/bin/bash

Conf="$1"

test -e /etc/firewall

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
#			echo "$Type" "`echo $Port | tr x :`" "$Value" "$Interface"
		else
			InputAccept "$Type" "$Port" "$Value" "$Interface"
#			echo "$Type" "$Port" "$Value" "$Interface"
		fi
    fi
	if [ "$Rule" = "fwd" ]; then
		if [ "`echo $Port | grep x`" != "" ]; then
			Forward "$Type" "`echo $Port | tr x :`" "$Value" "$Interface"
#			echo "$Type" "`echo $Port | tr x :`" "$Value" "$Interface"
		else
			Forward "$Type" "$Port" "$Value" "$Interface"
#			echo "$Type" "$Port" "$Value" "$Interface"
		fi

	fi
done < <(env | grep -E "udp|tcp")

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -j REJECT

env

exit 0
