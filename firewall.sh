#!/bin/bash

CONF=/etc/firewall

. $CONF

_CONF() {
  iptables -A INPUT -p $1 --dport $2 -s $3 -j ACCEPT
}

iptables -F
iptables --policy INPUT REJECT
iptables --policy FORWARD REJECT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

while read LINE; do

  VAR="`echo $LINE | cut -d\= -f2`"
  NAME="`echo $LINE | cut -d\= -f1`"
  TY="`echo $NAME | cut -d\_ -f1 | tr [A-Z] [a-z]`"
  PORT="`echo $NAME | cut -d\_ -f2`"
  _CONF "$TY" "$PORT" "$VAR"

done < <(env | grep -E "UDP|TCP")
