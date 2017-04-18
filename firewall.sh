#!/bin/bash

Conf="$1"

if [ "$Conf" = "" ]; then
    test -f /etc/firewall || echo "No configuration!" && exit 1
    . /etc/firewall
else
    . $Conf
fi

InputAccept() {
	iptables -A INPUT -i "$4" -p "$1" --dport "$2" -s "$3" -j ACCEPT
#	echo "INP - $*"
}

Forward() {
	iptables -t nat -A PREROUTING -i "$4" -p "$1" --dport "$2" -j DNAT --to-destination "$3"
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

iptables -A INPUT -p udp --sport 1:1024 -j ACCEPT
iptables -A INPUT -p tcp --sport 1:1024 -j ACCEPT
iptables -A INPUT -j REJECT

exit 0
