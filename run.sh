#! /bin/bash
ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' >> ips.txt
num=`cat ips.txt |wc -l`
s=$(sed -n '1p' ips.txt)
for ((i=1; i<=num; i ++)); do
port=$((3000+$i))
ips=$(sed -n "${i}p" ips.txt)
echo "internal: $s  port =$port"  >> $port.conf
echo "external: $ips" >> $port.conf
echo "socksmethod: username
user.privileged:root
user.notprivileged: nobody
client pass {
        from: 0.0.0.0/0 port 1-65535 to: 0.0.0.0/0
}
socks pass {
        from: 0.0.0.0/0 port 1-65535 to: 0.0.0.0/0
        protocol: tcp udp
}" >> $port.conf
echo "$ips:$s:$port:" >> done.txt
sockd -f /etc/s5conf/$port.conf &
done
