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

  TY="`$LINE | cut -d\_ -f1`"
  PORT="`$LINE | cut -d\_ -f2`"
  eval VAR="\$${TY}_${PORT}"
  _CONF "$TY" "$PORT" "$VAR"

done < <(env | egrep "TCP|UDP" | cut -d\= -f1)
