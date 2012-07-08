#!/bin/bash
# logTraffic.sh: Generate a log entry with IT mandated fields

## Mandatory variables
sessionStart="UNSET"
clientHostAddress="UNSET"
clientUID="UNSET"
sessionDuration="UNSET"
sent="UNSET"
received="UNSET"

## Parse variables

if [ ! -z "$time_ascii" ]; then
        sessionStart=$time_ascii
fi

if [ ! -z "$trusted_ip" ]; then
        clientHostAddress=$trusted_ip
fi

if [ ! -z "$username" ]; then
        clientUID=$username
fi

if [ ! -z "$time_duration" ]; then
        sessionDuration=$time_duration
fi

if [ ! -z "$bytes_sent" ]; then
        sent=$bytes_sent
fi

if [ ! -z "$bytes_received" ]; then
        received=$bytes_received
fi


#echo $@ >> /root/vpnplatform/scripts/users-sessions
#echo "Client Disconnect: Username: $clientUID HostIP: $clientHostAddress"  >> /root/vpnplatform/scripts/users-sessions
if [ "$1" = "client-connected" ]; then
echo `date +%Y-%m-%d_%H-%M` EDT - User : "$common_name" connected from IP $clientHostAddress, Protocole : $2 and assignd IP : $ifconfig_pool_remote_ip >> /root/vpnplatform/scripts/users-sessions
#echo "Client Connected: Username: "$common_name" HostIP: $clientHostAddress"  >> /root/vpnplatform/scripts/users-sessions
exit 0
fi
echo `date +%Y-%m-%d_%H-%M` EDT - User : "$common_name" disconnected, he was connecting from IP : "$clientHostAddress" and used Protocole : $2, Session Duration: $sessionDuration seconds,  Session Traffic: $sent bytes were sent and $received bytes were received and used the local IP : $ifconfig_pool_remote_ip >> /root/vpnplatform/scripts/users-sessions
