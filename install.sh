#! /bin/bash
sed -i '/install.sh/'d  /etc/rc.d/rc.local
ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}' >> ips.txt
s=$(sed -n '1p' ips.txt|awk -F '.' '{print $3$4}')
useradd user$s -s /bin/false ;echo 123654987|passwd --stdin user$s
wget  http://www.inet.no/dante/files/dante-1.4.3.tar.gz &&mv dante-1.4.3.tar.gz dante.tar.gz &&tar -xvzf dante.tar.gz&&cd dante-1.4.3&&./configure && make && make install&&sockd -v
mkdir /etc/s5conf&&cd /etc/s5conf&&echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf&&echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf&&sysctl -p&&sysctl -n net.ipv4.tcp_congestion_control&&lsmod | grep bbr
wget https://raw.githubusercontent.com/slot552/test/main/run.sh&&chmod u+x run.sh&&./run.sh&& ls -1 *.conf >conf.txt&&wget https://raw.githubusercontent.com/slot552/test/main/rerun.sh&&chmod u+x rerun.sh&&echo "/etc/s5conf/rerun.sh" >> /etc/rc.d/rc.local&&chmod +x /etc/rc.d/rc.local&&echo "10 20 * * * root  /etc/s5conf/rerun.sh" >> /etc/crontab&&service crond restart&&cd /root&&wget https://raw.githubusercontent.com/slot552/test/main/jiankong.sh&&chmod u+x jiankong.sh&&echo "*/59 * * * * root /root/jiankong.sh" >> /etc/crontab&&service crond restart&&cat /etc/s5conf/done.txt
done
