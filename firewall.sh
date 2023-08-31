root@dolf:/usr/local/bin# cat firewall.sh 
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
wan="eth0"
lan="eth1"
#      1.  2.   3.  4.   5.
inp_eth0_tcp_80="0.0.0.0/0"
inp_eth0_tcp_1024x2000="0.0.0.0/0"
fwd_eth0_tcp_80="10.0.0.1"
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
	interface="$1"
	type="$2"
	port="${3//x/:}"
	value="${4//\"/}"

	if [ "$(echo "$value" | wc -w)" != 1 ]; then
		for var in $value; do
			iptables -A INPUT -i "$interface" -p "$type" --dport "$port" -s "$var" -j ACCEPT
			ErrorTest "$?"
		done
	else
		iptables -A INPUT -i "$interface" -p "$type" --dport "$port" -s "$value" -j ACCEPT
		ErrorTest "$?"
	fi
}

OutputAccept() {
	interface="$1"
	type="$2"
	port="${3//x/:}"
	value="${4//\"/}"

	if [ "$(echo "$value" | wc -w)" != 1 ]; then
		for Var in $value; do
			iptables -A OUTPUT -o "$interface" -p "$type" --sport "$port" -s "$Var" -j ACCEPT
			ErrorTest "$?"
		done
	else
		iptables -A OUTPUT -o "$interface" -p "$type" --sport "$port" -s "$value" -j ACCEPT
		ErrorTest "$?"
	fi
}

Forward() {
	interface="$1"
	type="$2"
	port="${3//x/:}"
	value="${4//\"/}"
	if [ "$(echo "$3" | wc -w)" != 1 ]; then
		echo "Forward not possible for $*!"
	else
		iptables -t nat -A PREROUTING -i "$interface" -p "$type" --dport "$port" -j DNAT --to "$value:$port"
		ErrorTest "$?"
	fi
}

ProcessRule() {
case "$1" in
  "inp")
    shift; InputAccept $*
  ;;
  "fwd")
    shift; Forward $*
  ;;
  "out")
    shift; OutputAccept $*
  ;;
  *)
    echo "Woops! Unkonwn rule"
  ;;
esac
}

ResetRules() {
	if [ "$1" != "" ]; then
		iptables -t "$1" -F
	else
		TableList="filter nat mangle raw security "
		for Table in $TableList; do
			iptables -t "$Table" -F
		done
	fi
	iptables -F
}

Conf="$1"

if [[ "$1" = "-h" || "$1" = "--help" ]]; then
	Help
	exit 0
fi

test -e /etc/firewall || ( echo "No configuration file at /etc/firewall"; exit 1 )

if [ "$?" != "0" ]; then
	Vars="$(LoadConfig $Conf)"
	eval "$Vars"
else
	Vars="$(LoadConfig /etc/firewall)"
	eval "$Vars"
fi

ResetRules

iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

if [ "$(grep -v "#" /etc/hosts.deny)" != "" ]; then
	while read Var; do
		iptables -A INPUT -i "${wan:=$(route | grep default | awk '{print $8}')}" -s "$Var" -j REJECT
	done < <(grep -v "#" /etc/hosts.deny)
fi

while read Var; do
	tmp="${Var//_/\ }\""
	ProcessRule ${tmp//=/\ \"}
done < <(env | egrep "udp_|tcp_|fwd_")

env | grep -q "fwd_" && sysctl -w net.ipv4.conf.all.route_localnet=1 > /dev/null

iptables -A INPUT -i "${wan:=$(route | grep default | awk '{print $8}')}" -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i "${wan:=$(route | grep default | awk '{print $8}')}" -j REJECT

env | grep -q "lan=" || exit 0

sysctl -w net.ipv4.ip_forward=1 > /dev/null
iptables -A FORWARD -o $wan -i $lan -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A POSTROUTING -o $wan -j MASQUERADE

exit 0
