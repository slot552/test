#! /bin/bash
ps -efww|grep "sockd -f" |grep -v grep|cut -c 9-16|xargs kill -9
/usr/local/sbin/sockd -f /etc/s5conf/same.conf &
