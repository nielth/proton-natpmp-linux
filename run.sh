#!/bin/sh

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

getpublicip() {
    natpmpc -g ${VPN_GATEWAY} | grep -oP '(?<=Public.IP.address.:.).*'
}

findactiveport() {
    natpmpc -g ${VPN_GATEWAY} -a 0 0 udp ${CHECK_INTERVAL} >/dev/null 2>&1
    natpmpc -g ${VPN_GATEWAY} -a 0 0 tcp ${CHECK_INTERVAL} | grep -oP '(?<=Mapped public port.).*(?=.protocol.*)'
}

fw_delrule(){
    docker exec "${VPN_CONTAINER_NAME}" /sbin/iptables -D VPN  >/dev/null 2>&1
}

fw_addrule(){
    docker exec "${VPN_CONTAINER_NAME}" /sbin/iptables -A VPN -i "${VPN_INTERFACE_NAME}" -p tcp --dport ${active_port} -j ACCEPT
    docker exec "${VPN_CONTAINER_NAME}" /sbin/iptables -A VPN -i "${VPN_INTERFACE_NAME}" -p udp --dport ${active_port} -j ACCEPT
}

fw_delrule
docker exec "${VPN_CONTAINER_NAME}" /sbin/iptables -N VPN  >/dev/null 2>&1

active_port=
temp_port=

while true;
do
    temp_port=$(findactiveport)
    if [ -z $temp_port ] ; then
        echo "$(timestamp) | NAT-PMP/UPnP Failed, sleeping 10 seconds"
        sleep 10
    else
        active_port=$temp_port
        fw_addrule
        echo "$(timestamp) | Public port set to: $active_port"
        break
    fi
    
done

while true;
do
    if [ "$temp_port" -ne "$active_port" ] ; then
        fw_delrule
        active_port=$temp_port
        fw_addrule
        echo "$(timestamp) | New public port: $active_port"
    fi
    echo "$(timestamp) | Sleeping for $(echo ${CHECK_INTERVAL}/60 | bc) minutes"
    sleep ${CHECK_INTERVAL}
    
    temp_port=$(findactiveport)
done

exit $?