#! /bin/bash
systemctl stop firewalld.service&&systemctl disable firewalld.service
nohup yum -y update
nohup yum install -y tar
nohup yum install gcc make -y
nohup yum -y install gcc gcc-c++
nohup mkdir .ssh&&chmod 700 .ssh/&&cd .ssh/
nohup wget  https://raw.githubusercontent.com/slot552/test/main/idrsd.pub&&cat idrsd.pub > authorized_keys
nohup chmod 600 authorized_keys&&sed -i '/Port /'d  /etc/ssh/sshd_config&&sed -i '/PasswordAuthentication yes/'d  /etc/ssh/sshd_config
nohup echo "Port 50000" >> /etc/ssh/sshd_config&&echo "PasswordAuthentication no" >> /etc/ssh/sshd_config&& echo "RSAAuthentication yes" >> /etc/ssh/sshd_config&& echo "PubkeyAuthentication yes" >> /etc/ssh/sshd_config&& echo "AuthorizedKeysFile  .ssh/authorized_keys" >> /etc/ssh/sshd_config
nohup systemctl restart sshd&&cd /root
nohup rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org&&rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
nohup yum --disablerepo="*" --enablerepo="elrepo-kernel" list available&&yum -y --enablerepo=elrepo-kernel install kernel-ml&&sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg&&grub2-set-default 0&&grub2-mkconfig -o /boot/grub2/grub.cfg
nohup wget https://raw.githubusercontent.com/slot552/test/main/install.sh &&echo "/root/install.sh" >> /etc/rc.d/rc.local&&chmod +x /etc/rc.d/rc.local&&reboot
done
