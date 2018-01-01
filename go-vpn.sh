#!/bin/sh
apt-get update
apt-get --assume-yes install openvpn
apt-get --assume-yes install easy-rsa
apt-get --assume-yes install heirloom-mailx
cd /usr/share/easy-rsa/
mkdir keys
touch keys/index.txt
echo 01 > keys/serial
source vars
export KEY_EMAIL="$owner"
./pkitool --initca
./pkitool --server server
./build-dh
./pkitool client
cd keys
mv *.pem *.crt *.csr *.key /etc/openvpn
cd /etc/openvpn
wget --no-check-certificate https://raw.githubusercontent.com/junhz/openvpn-vm/master/server.conf
echo "" >> server.conf
echo "proto $protocol" >> server.conf
echo "port $port" >> server.conf
wget --no-check-certificate -O client.ovpn https://raw.githubusercontent.com/junhz/openvpn-vm/master/client.conf
echo "" >> client.ovpn
echo "proto $protocol" >> client.ovpn
cat /etc/resolv.conf | grep "^nameserver" | sed "s/nameserver/dhcp-option DNS/" >> client.ovpn
echo "remote $(dig +short myip.opendns.com @resolver1.opendns.com) $port" >> client.ovpn
echo "<ca>" >> client.ovpn
cat ca.crt | grep -A 100 "BEGIN CERTIFICATE" | grep -B 100 "END CERTIFICATE" >> client.ovpn
echo "</ca>" >> client.ovpn
echo "<cert>" >> client.ovpn
cat client.crt | grep -A 100 "BEGIN CERTIFICATE" | grep -B 100 "END CERTIFICATE" >> client.ovpn
echo "</cert>" >> client.ovpn
echo "<key>" >> client.ovpn
cat client.key | grep -A 100 "BEGIN PRIVATE KEY" | grep -B 100 "END PRIVATE KEY" >> client.ovpn
echo "</key>" >> client.ovpn
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
iptables -A FORWARD -i eth0 -o tun0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -s 10.9.8.0/24 -o eth0 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.9.8.0/24 -o eth0 -j MASQUERADE
#zip?
echo "please use attached openvpn configuration" | mailx -v -s "your vpn server is ready" -S smtp-use-starttls -S smtp-auth=login -S smtp=smtp://$smtp -S smtp-auth-user=$owner -S smtp-auth-password=$password -S ssl-verify=ignore -r $owner -a client.ovpn $client
openvpn --config server.conf
