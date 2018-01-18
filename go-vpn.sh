#!/bin/bash
apt-get update
apt-get --assume-yes install openvpn
apt-get --assume-yes install heirloom-mailx
cd /etc/openvpn
openvpn --genkey --secret static.key
wget --no-check-certificate https://raw.githubusercontent.com/junhz/openvpn-vm/static/server.conf
echo "" >> server.conf
echo "proto $protocol" >> server.conf
echo "port $port" >> server.conf
wget --no-check-certificate -O client.ovpn https://raw.githubusercontent.com/junhz/openvpn-vm/static/client.conf
echo "" >> client.ovpn
echo "proto $protocol" >> client.ovpn
cat /etc/resolv.conf | grep "^nameserver" | sed "s/nameserver/dhcp-option DNS/" >> client.ovpn
echo "remote $(dig +short myip.opendns.com @resolver1.opendns.com) $port" >> client.ovpn
echo "<secret>" >> client.ovpn
cat static.key | grep -A 100 "BEGIN OpenVPN Static key V1" | grep -B 100 "END OpenVPN Static key V1" >> client.ovpn
echo "</secret>" >> client.ovpn
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
iptables -A FORWARD -i eth0 -o tun0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 10.9.8.0/24 -o eth0 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.9.8.0/24 -o eth0 -j MASQUERADE
#zip?
echo "please use attached openvpn configuration" | mailx -v -s "your vpn server is ready" -S smtp-use-starttls -S smtp-auth=login -S smtp=smtp://$smtp -S smtp-auth-user=$owner -S smtp-auth-password=$password -S ssl-verify=ignore -r $owner -a client.ovpn $client
openvpn --config server.conf
