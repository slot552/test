#! /bin/bash
echo "internal: eth0  port =32336
external: eth0
external.rotation: same-same
socksmethod: username
user.privileged:root
user.notprivileged: nobody
client pass {
        from: 0.0.0.0/0 port 1-65535 to: 0.0.0.0/0
}
socks pass {
        from: 0.0.0.0/0 port 1-65535 to: 0.0.0.0/0
        protocol: tcp udp
}" >> same.conf
ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' >> ips.txt
num=`cat ips.txt |wc -l`
u=$(tail -1 /etc/passwd | sort -r | grep '/home' | cut -d: -f1)
for ((i=1; i<=num; i ++)); do
ips=$(sed -n "${i}p" ips.txt)
echo "$ips $ips:32336:$u:123654987" >> done.txt
done
