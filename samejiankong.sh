#! /bin/bash
ps -efww|grep "sockd -f" |grep -v grep|cut -c 86-94 >> tmp.txt
run=`cat /root/tmp.txt |wc -l`
rm -rf tmp.txt
num= 1
if  [[ $run < $num ]]; then
  bash /etc/s5conf/rerun.sh
fi
