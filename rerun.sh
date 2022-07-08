#! /bin/bash
ps -efww|grep "sockd -f" |grep -v grep|cut -c 9-16|xargs kill -9
num=`cat conf.txt |wc -l`
for ((i=1; i<=num; i ++)); do
conf=$(sed -n "${i}p" conf.txt)
sockd -f /etc/s5conf/$conf &
done
