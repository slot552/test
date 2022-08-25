#! /bin/bash
ps -efww|grep "sockd -f" |grep -v grep|cut -c 9-16|xargs kill -9
num=`cat /etc/s5conf/conf.txt |wc -l`
for ((i=1; i<=num; i ++)); do
conf=$(sed -n "${i}p" /etc/s5conf/conf.txt)
/usr/local/sbin/sockd -f /etc/s5conf/$conf &
done
