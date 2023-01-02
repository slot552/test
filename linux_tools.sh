#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
###########################################################
## Author        : Shihua
## Email         : 93959@163.com
## Create Time   : 2019-10-02 11:23:21
## Last modified : 2022-08-03 11:20:02
## Filename      : linux_tools.sh
## Description   : linux系统多IP配置、测速、查看硬件配置等
###########################################################
# Usage: 
Usage(){
clear;[[ -f /usr/bin/wget ]] || (echo -e " Installing  wget ..." && (yum install wget -y >/dev/null 2>&1 || apt-get install wget -y >/dev/null 2>&1));echo "Downloading linux_tools.sh ..." ; wget --user=rak --password=raksmart.com http://198.200.61.61:8023/linux_tools.sh >/dev/null 2>&1 && sleep 2s && bash linux_tools.sh
}
# version
sh_ver="2.4"
# Colors
RED='\033[0;31m'
BLUE='\033[1;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
SKYBLUE_B='\033[1;36m'
PURPLE_F='\033[5;35m'
PURPLE='\033[0;35m'
PLAIN='\033[0m'
# lables
Tip="${GREEN}[注意]${PLAIN}"
Info="${GREEN}[信息]${PLAIN}"
Error="${RED}[错误]${PLAIN}"
Notice="${BLUE}[提示]${PLAIN}"
# ============ 退出时删除脚本及下载或产生的文件 STA ============
cancel() {
    echo -e "\n  Exiting..."
    echo -e "  Cleanup..."
    cd - >/dev/null 2>&1
    rm -rf ${self} >/dev/null 2>&1
    rm -rf /root/linux_tools.sh >/dev/null 2>&1
    rm -rf /root/speedtest.py >/dev/null 2>&1
    rm -rf linux_tools.sh >/dev/null 2>&1
    rm -rf speedtest.py >/dev/null 2>&1
    rm -rf $0 >/dev/null 2>&1
    unlink $0 >/dev/null 2>&1
    cd ~ >/dev/null 2>&1
    rm -rf ${self} >/dev/null 2>&1
    rm -rf /root/linux_tools.sh >/dev/null 2>&1
    rm -rf /root/speedtest.py >/dev/null 2>&1
    rm -rf linux_tools.sh >/dev/null 2>&1
    rm -rf speedtest.py >/dev/null 2>&1
    rm -rf $0 >/dev/null 2>&1
    unlink $0 >/dev/null 2>&1
    echo -e "  Done...\n"
    exit
}
trap cancel SIGINT
# ============ 退出时删除脚本及下载或产生的文件 END ============
# ##############################################################
# ================== 暂停按任意键继续模块 STA ==================
get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}
pause(){
    [[ "x$1" != "x" ]] && echo -e " $1\c"
    echo -e " ${Notice} 请按任意键返回主菜单！\c"
    char=`get_char`
    start_menu
}
# ================== 暂停按任意键继续模块 END ==================
# ##############################################################
# ================== 获取配置IP的网卡名称 STA ==================
# 获取UP状态的网卡并选择要配置IP的网卡
get_nic_name(){
    clear
    i=0
    j=1
    n=`ip a | grep "^[0-9]: " | tr -d : | awk '/state UP/{print $2}' | wc -l`
    if [ $n == 0 ];then
        pause "\n ${Error}没有检测到UP状态网卡！"
    elif [ $n == 1 ];then
        upnic=`ip a | awk '/state UP/{print $2}' | tr -d ":"`
        version_select_nic
        echo -e "\n ${Info}系统当前UP状态网卡只有：${upnic}，IP将默认配置到该网卡上"
        [[ ${num} == 1 ]] && analyze_sip
        [[ ${num} == 2 ]] && analyze_aip
    else
        echo -e "\n ${Info}系统当前UP状态网卡有："
        ip a | grep "^[0-9]: " | tr -d : | awk '/state UP/{print $2}' | while read line
        do
            echo -e " $j. $line"
            let j++
        done
        echo && read -p " 请选择你要配置IP的网卡编号[1-$n]:" i
        [[ ${i} == 0 ]] && start_menu
        if [ $i -ge 1 ] >/dev/null 2>&1 && [ $i -le $n ] >/dev/null 2>&1 ;then
            upnic=`ip a | grep "^[0-9]: " | tr -d : | awk '/state UP/{print $2}' | awk "{if(NR==$i)print}"`
            version_select_nic
            echo -e "\n ${Info}你选择将IP配置到 ${upnic} 网卡上"
            [[ ${num} == 1 ]] && analyze_sip
            [[ ${num} == 2 ]] && analyze_aip
        else
            echo -e " ${Error}输入有误，请重新输入！"
            sleep 2s
            get_nic_name
        fi
    fi
}
# 检测系统版本及其对应的网卡配置文件是否存在，如果存在将原配置文件备份
version_select_nic(){
    timestamp=$(date '+%Y%m%d%H%M%S')
    if [ ${release} = "centos" ]; then
        nicfile=ifcfg-${upnic}
        cd /etc/sysconfig/network-scripts/
        if [ -e ${nicfile} ]; then
            [[ -d bak ]] || mkdir bak
            cp ${nicfile} ./bak/${nicfile}.bak.${timestamp}
            sed -i 's/"//g' ifcfg-${upnic}
            sed -i 's/^IPADDR0/IPADDR/g' ifcfg-${upnic}
            sed -i 's/^PREFIX0/PREFIX/g' ifcfg-${upnic}
            sed -i 's/^GATEWAY0/GATEWAY/g' ifcfg-${upnic}
        else
            pause "${Error} ${nicfile}网卡配置文件不存在，请手动处理!"
        fi
    elif [ ${release} = "ubuntu" ]; then
        if [ ${version1} -lt 18 ]; then
            cd /etc/network/ && [[ -d bak ]] || mkdir bak
            nicfile=interfaces
            [[ -e ${nicfile} ]] && cp ${nicfile} ./bak/${nicfile}.bak.${timestamp} || pause "${Error} ${nicfile}网卡配置文件不存在，请手动处理!"
        else 
            filenum=$(ls /etc/netplan/*.yaml | wc -l)
            if [ ${filenum} -eq 1 ]; then
                cd /etc/netplan/ && [[ -d bak ]] || mkdir bak
                nicfile=*.yaml
                cp $(echo ${nicfile}) ./bak/$(echo ${nicfile}).bak.${timestamp}
            else
                pause "${Error} /etc/netplan/*.yaml网卡配置文件不存在，请手动处理!"
            fi
        fi
    else
        pause "${Tip}:不支持当前操作系统!!!"
    fi
}
# ================== 获取配置IP的网卡名称 END ==================
# ##############################################################
# ========================== IP配置 STA ========================
#根据系统版本和IP数据选择对应的配置方法
version_select(){
    if [ ${release} = "centos" ]; then 
        echo -e " ${Notice}要配置的IP个数为: "${RED}${u}${PLAIN}""
        echo -e " 如需以ifcfg-${upnic}-range*形式配置，请输入1;"
        echo -e " 按Enter键，默认都配置在ifcfg-${upnic}该文件中:\c" && read x
        if [ ${x} -eq 0 ] 2>/dev/null ; then
            start_menu
        elif [ ${x} -eq 1 ] 2>/dev/null ; then
            CentOS_range
        else
            CentOS_manfile
        fi
    elif [ ${release} = "ubuntu" ]; then
        if [ ${version1} -lt 18 ]; then
            ubuntu_old
        else
            ubuntu_new
        fi
    else
        echo -e " ${Tip}:不支持当前操作系统，3秒后返回主菜单"
        sleep 2s
        start_menu
    fi
}
# CentOS 以range形式添加连续IP(包含整段IP) 
CentOS_range(){
    if [ ${version1} -ge 7 ];then
        # grep -qEi "^NM_CONTROLLED=no$" ${nicfile} || echo "NM_CONTROLLED=no" >> ${nicfile}
        sed -i '/^NM_CONTROLLED/d' ${nicfile}
        echo "NM_CONTROLLED=no" >> ${nicfile}
    fi
    if ls ${nicfile}-range* >/dev/null 2>&1 ; then 
        end_range_num=`ls ${nicfile}-range* | awk -F- 'END{print $3}' | cut -c6-`
        case ${end_range_num} in
            [0-8])
                next_range_num=$[${end_range_num}+1]
                ;;
            '9')
                next_range_num=a
                ;;
            'a')
                next_range_num=b
                ;;
            'b')
                next_range_num=c
                ;;
            'c')
                next_range_num=d
                ;;
            'd')
                next_range_num=e
                ;;
            'e')
                next_range_num=f
                ;;
            *)
            echo -e " ${Tip}range形式最多只能配置16段！！！"
                echo -e " 以上IP将配置到主网卡配置文件ifcfg-${upnic}中...\n"
                sleep 2s
                CentOS_manfile
                ;;
        esac
        range="range${next_range_num}"
        start_num=`awk -F. '/IPADDR_START/{print $4}' ${nicfile}-range${end_range_num}`
        end_num=`awk -F. '/IPADDR_END/{print $4}' ${nicfile}-range${end_range_num}` 
        clone_num=`awk -F= '/CLONENUM_START/{print $2}' ${nicfile}-range${end_range_num}`
        clonenum=$[${end_num}-${start_num}+${clone_num}+1]
    else
        range=range0
        clonenum=0
    fi
    echo "DEVICE=${upnic}" > ${nicfile}-${range}
    echo "ONBOOT=yes" >> ${nicfile}-${range}
    echo "BOOTPROTO=static" >> ${nicfile}-${range}
    echo "IPADDR_START=${start_ip}" >> ${nicfile}-${range}
    echo "IPADDR_END=${end_ip}" >> ${nicfile}-${range}
    if [ ${version1} -ge 7 ];then
        echo "PREFIX=${p}" >> ${nicfile}-${range}
    else
        echo "NETMASK=${netmask}" >> ${nicfile}-${range}
    fi
    echo "CLONENUM_START=${clonenum}" >> ${nicfile}-${range}
    echo "GATEWAY=${gateway_ip}" >> ${nicfile}-${range}
    more_config
}
# CentOS 直接回车默认将IP添加到主配置文件中，可选择1以range形式配置
CentOS_manfile(){
    s=`awk -F"=" '/^IPADDR/{print $1}' ${nicfile} | tr -d "a-zA-Z" | awk 'BEGIN {max = 0} {if ($1+0> max+0) max=$1} END {print max+1}'`
    e=$[${s}+${u}-1]
    n=$[${sip}-${s}]
    for ((i=${s};i<=${e};i++))
    do
        let j=$i+$n
        echo "IPADDR$i=${a}.${b}.${c}.$j" >> ${nicfile}
        if [ ${version1} -ge 7 ];then
            echo "PREFIX$i=${p}" >> ${nicfile}
        else
            echo "NETMASK$i=${netmask}" >> ${nicfile}
        fi
        echo GATEWAY$i=${gateway_ip} >> ${nicfile}
    done
    if [ ls /etc/sysconfig/network-scripts/ | grep range | grep -Ev "bk|bak|backup" ]; then
        sed -i '/^NM_CONTROLLED/d' ${nicfile}
        echo "NM_CONTROLLED=no" >> ${nicfile}
    fi
    more_config
}
# Ubuntu16 及以下版本添加IP配置方法
ubuntu_old(){
    upnicm="${upnic}:*"
    s=`awk '{if($2~"'${upnicm}'") {print $2}}' ${nicfile} | awk -F : 'BEGIN {max = 0} {if ($2+0> max+0) max=$2} END {print max+1}'`
    e=$[${s}+${u}-1]
    n=$[${sip}-${s}]
    for ((i=${s};i<=${e};i++))
    do
        echo "auto ${upnic}:$i" >> ${nicfile}
        echo "iface ${upnic}:$i inet static" >> ${nicfile}
        let j=$i+$n
        echo -e "\taddress ${a}.${b}.${c}.$j" >> ${nicfile}
        echo -e "\tnetmask ${netmask}" >> ${nicfile}
        echo -e "\tgateway ${gateway_ip}\n" >> ${nicfile}
    done
    more_config
}
# Ubuntu18 及以上版本添加IP配置方法
ubuntu_new(){
    echo "      addresses: " >> ${nicfile}
    for ((i=${sip};i<=${eip};i++))
    do
        echo -e "        - ${a}.${b}.${c}.${i}/${p}" >> ${nicfile}
    done
    echo -e "      gateway4: ${gateway_ip}" >> ${nicfile}
    more_config
}
# IP配置后的提示
more_config(){
    echo -e " ${Info}IP已配置到系统中，重启网络服务后生效！\n"
    read -p " 1.配置连续IP；2.配置整段IP；3.重启网络服务；其它返回主菜单: " num
    if [ ${num} == 1 ] 2>/dev/null ; then
        analyze_sip
    elif [ ${num} == 2 ] 2>/dev/null ; then
        analyze_aip
    elif [ ${num} == 3 ] 2>/dev/null ; then
        restart_network
    else
        clear
        start_menu
    fi
}
# ========================== IP配置 END ========================
# ##############################################################
# ========================= 重启网络服务 STA ===================
# 重启网络服务
restart_network(){
    clear
    echo -e " ${Info} 正在重启网络服务...\c"
    if [[ ${release} = "centos" && ${version1} -le 6 ]]; then
        service network restart >/dev/null 2>&1 && service network restart
    elif [[ ${release} = "centos" && ${version1} -eq 7 ]]; then
        systemctl restart network >/dev/null 2>&1 && systemctl restart network
    elif [[ ${release} = "centos" && ${version1} -eq 8 ]]; then
        nmcli c reload && nmcli c up ${upnic} >/dev/null 2>&1 && nmcli c reload && nmcli c up
    elif [[ ${release} = "ubuntu" && ${version1} -le 16 ]]; then
        /etc/init.d/networking restart >/dev/null 2>&1 && /etc/init.d/networking restart
    elif [[ ${release} = "ubuntu" && ${version1} -ge 18 ]]; then
        netplan apply >/dev/null 2>&1 && netplan apply
    else
        echo -e " ${Tip}:不支持当前操作系统，3秒后返回主菜单"
        sleep 3s
        start_menu
    fi
    [ $? != 0 ] || pause "[${GREEN}OK${PLAIN}]\n"
}
# ========================= 重启网络服务 END ===================
# ##############################################################
# ========================== 整段IP检测 STA ====================
# 判断输入合法性
check_aip(){
    echo 
    set aip=0
    read -p " 请输入要配置的IP段 [示例:108.186.1.0/24]: " aip
    [[ ${aip} == 0 ]] && start_menu
    echo ${aip} | grep "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}\/2[4-9]$" > /dev/null; 
    if [ $? -ne 0 ];then 
    #IP地址必须为全数字 
        return 1 
    fi 
    ipaddr=${aip}
    a=`echo ${ipaddr} | awk -F '[./]+' '{print $1}'`
    b=`echo ${ipaddr} | awk -F '[./]+' '{print $2}'`
    c=`echo ${ipaddr} | awk -F '[./]+' '{print $3}'`
    d=`echo ${ipaddr} | awk -F '[./]+' '{print $4}'`
    p=`echo ${ipaddr} | awk -F '[./]+' '{print $5}'`
    for num in $a $b $c $d 
    do 
        if [ ${num} -gt 255 ] || [ ${num} -lt 0 ];then 
        #IP的每个数值必须在0-255之间
            return 1 
        fi 
    done 
    if [ ${p} -gt 29 ] || [ ${p} -lt 24 ];then 
    #IP的网络位数值在24-29之间
        return 1
    elif [ ${p} == 24 ] && [ ${d} -ne 0 ];then 
    #当网络位数为24时,IP段最后一位必需为0；
        return 1
    elif [ ${p} == 25 ] && [ $[${d}%128] -ne 0 ];then 
    #当网络位数为25时,IP段最后一位必需为128的整数倍；
        return 1
    elif [ ${p} == 26 ] && [ $[${d}%64] -ne 0 ];then 
    #当网络位数为26时,IP段最后一位必需为64的整数倍；
        return 1
    elif [ ${p} == 27 ] && [ $[${d}%32] -ne 0 ];then 
    #当网络位数为27时,IP段最后一位必需为32的整数倍；
        return 1
    elif [ ${p} == 28 ] && [ $[${d}%16] -ne 0 ];then 
    #当网络位数为28时,IP段最后一位必需为16的整数倍；
        return 1
    elif [ ${p} == 29 ] && [ $[${d}%8] -ne 0 ];then 
    #当网络位数为29时,IP段最后一位必需为0或8的整数倍；
        return 1
    fi
    return 0
}
# 通过输入的IP段获取起止IP、网关、掩码
analyze_aip(){
    check_aip
    if [ $? == 1 ];then 
        echo -e " ${Error}输入有误，请重新输入！！"
        analyze_aip
    fi
    sip=$[${d}+1]
    case ${p} in
        '24')
            g=0
            u=253
            eip=$[${d}+253]
            ;;
        '25')
            g=128
            u=125
            eip=$[${d}+125]
            ;;
        '26')
            g=192
            u=61
            eip=$[${d}+61]
            ;;
        '27')
            g=224
            u=29
            eip=$[${d}+29]
            ;;
        '28')
            g=240
            u=13
            eip=$[${d}+13]
            ;;
        '29')
            g=248
            u=5
            eip=$[${d}+5]
    esac
    gip=$[${eip}+1]
    start_ip=${a}.${b}.${c}.${sip}
    end_ip=${a}.${b}.${c}.${eip}
    netmask=255.255.255.${g}
    gateway_ip=${a}.${b}.${c}.${gip}
    echo -e "\n 您要配置的IP详细信息如下：\n 起始IP：${start_ip}"
    echo -e " 结束IP：${end_ip}"
    echo -e " 网关IP：${gateway_ip}"
    echo -e " 子网掩码：${netmask}\n"
    version_select
}
# ========================== 整段IP检测 END ====================
# ##############################################################
# ========================== 连续IP检测 STA ====================
check_sip(){
    echo -e "\n 例如配置: 108.186.1.1/27-108.186.1.10/27 "
    echo -e " 则请输入: 108.186.1.1-10/27 "
    set sip=0
    read -p " 请输入要配置的连续IP: " sip
    [[ ${sip} == 0 ]] && start_menu
    echo ${sip} | grep "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}-[0-9]\{1,3\}\/2[4-9]$" > /dev/null; 
    if [ $? -ne 0 ];then 
    #IP地址必须为全数字 
        return 1
    fi 
    ipaddr=${sip}
    a=`echo ${ipaddr} | awk -F '[./-]+' '{print $1}'`
    b=`echo ${ipaddr} | awk -F '[./-]+' '{print $2}'`
    c=`echo ${ipaddr} | awk -F '[./-]+' '{print $3}'`
    d=`echo ${ipaddr} | awk -F '[./-]+' '{print $4}'`
    e=`echo ${ipaddr} | awk -F '[./-]+' '{print $5}'`
    p=`echo ${ipaddr} | awk -F '[./-]+' '{print $6}'`
    for num in $a $b $c $d $e
    do 
        if [ ${num} -gt 255 ] || [ ${num} -lt 0 ];then 
        #IP的每个数值必须在0-255之间
            return 1
        fi 
    done 
    if [ ${d} -gt 253 ] || [ ${d} -lt 1 ];then 
    #起始主机位应在1-253之间
        return 1
    elif [ ${e} -gt 253 ] || [ ${e} -lt ${d} ];then 
    #结束主机位应在1-253之间，且大于或等于起始主机位
        return 1
    elif [ ${p} -gt 29 ] || [ ${p} -lt 24 ];then 
    #IP的网络位数值在24-29之间
        return 1
    fi
    case ${p} in
        '24')
            g=0
            i=254
            ;;
        '25')
            u=128
            g=128
            for ((i=126;i<${d};i+=${u}))
            do
                gip=$i
            done
            if [ ${d} -ge ${i} ] || [ ${e} -ge ${i} ];then 
            #起始IP和结束IP都不能大于或等于网关IP
                return 1
            fi
            ;;
        '26')
            u=64
            g=192
            for ((i=62;i<${d};i+=${u}))
            do
                gip=$i
            done
            if [ ${d} -ge ${i} ] || [ ${e} -ge ${i} ];then 
                return 1
            fi
            ;;
        '27')
            u=32
            g=224
            for ((i=30;i<${d};i+=${u}))
            do
                gip=$i
            done
            if [ ${d} -ge ${i} ] || [ ${e} -ge ${i} ];then 
                return 1
            fi
            ;;
        '28')
            u=16
            g=240
            for ((i=14;i<${d};i+=${u}))
            do
                gip=$i
            done
            if [ ${d} -ge ${i} ] || [ ${e} -ge ${i} ];then 
                return 1
            fi
            ;;
        '29')
            u=8
            g=248
            for ((i=6;i<${d};i+=${u}))
            do
                gip=$i
            done
            if [ ${d} -ge ${i} ] || [ ${e} -ge ${i} ];then 
                return 1
            fi
    esac
    return 0
}
analyze_sip(){
    check_sip
    if [ $? == 1 ];then 
        echo -e " ${Error}输入有误，请重新输入！！！"
        analyze_sip
    fi
    u=$[${e}-${d}+1]
    sip=${d}
    eip=${e}
    gip=${i}
    start_ip=${a}.${b}.${c}.${d}
    end_ip=${a}.${b}.${c}.${e}
    netmask=255.255.255.${g}
    gateway_ip=${a}.${b}.${c}.${gip}
    echo -e "
 您要配置的IP详细信息如下：\n 起始IP：${start_ip}
 结束IP：${end_ip}
 网关IP：${gateway_ip}
 子网掩码：${netmask}\n"
    version_select
}
# ========================== 连续IP检测 END ====================
# ##############################################################
# ========================== 带宽测速 STA ======================
# speedtest测速
speed_test(){
    if [[ $1 == '' ]]; then
        temp=$(python speedtest.py --share 2>&1 || python3 speedtest.py --share 2>&1)
        is_down=$(echo "$temp" | grep 'Download')
        result_speed=$(echo "$temp" | awk -F ' ' '/results/{print $3}')
        if [[ ${is_down} ]]; then
            local REDownload=$(echo "$temp" | awk -F ':' '/Download/{print $2}')
            local reupload=$(echo "$temp" | awk -F ':' '/Upload/{print $2}')
            local relatency=$(echo "$temp" | awk -F ':' '/Hosted/{print $2}')
            temp=$(echo "$relatency" | awk -F '.' '{print $1}')
            if [[ ${temp} -gt 50 ]]; then
                relatency=" (*)"${relatency}
            fi
            local nodeName=$2
            temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
            if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
                printf "${GREEN}%-17s${RED}%-20s${SKYBLUE}%-12s${YELLOW}%-18s${PLAIN}\n" "${reupload}" "${REDownload}" "${relatency}" " ${nodeName}" | tee -a $log
#                printf "${GREEN}%-17s${RED}%-20s${SKYBLUE}%-12s${YELLOW}%-18s${BLUE}%-20s${PLAIN}\n" "${reupload}" "${REDownload}" "${relatency}" " ${nodeName}" " ${result_speed}" | tee -a $log
            fi
        else
            local cerror="ERROR"
        fi
    else
        temp=$(python speedtest.py --server $1 --share 2>&1 || python3 speedtest.py --server $1 --share 2>&1)
        is_down=$(echo "$temp" | grep 'Download') 
        result_speed=$(echo "$temp" | awk -F ' ' '/results/{print $3}')
        if [[ ${is_down} ]]; then
            local REDownload=$(echo "$temp" | awk -F ':' '/Download/{print $2}')
            local reupload=$(echo "$temp" | awk -F ':' '/Upload/{print $2}')
            local relatency=$(echo "$temp" | awk -F ':' '/Hosted/{print $2}')
            #local relatency=$(pingtest $3)
            #temp=$(echo "$relatency" | awk -F '.' '{print $1}')
            #if [[ ${temp} -gt 1000 ]]; then
            #    relatency=" - "
            #fi
            local nodeName=$2
            temp=$(echo "${REDownload}" | awk -F ' ' '{print $1}')
            if [[ $(awk -v num1=${temp} -v num2=0 'BEGIN{print(num1>num2)?"1":"0"}') -eq 1 ]]; then
                printf "${GREEN}%-17s${RED}%-20s${SKYBLUE}%-12s${YELLOW}%-18s${PLAIN}\n" "${reupload}" "${REDownload}" "${relatency}" " ${nodeName}" | tee -a $log
#                printf "${GREEN}%-17s${RED}%-20s${SKYBLUE}%-12s${YELLOW}%-18s${BLUE}%-20s${PLAIN}\n" "${reupload}" "${REDownload}" "${relatency}" " ${nodeName}" " ${result_speed}" | tee -a $log
            fi
        else
            local cerror="ERROR"
        fi
    fi
}
print_speedtest() {
    printf "%-18s%-20s%-12s%-18s\n" " Upload Speed" "Download Speed" "Latency" "Node Name" | tee -a $log
#    printf "%-18s%-20s%-12s%-18s%-20s\n" " Upload Speed" "Download Speed" "Latency" "Node Name" "Share results" | tee -a $log
    speed_test '' 'Speedtest.net'
    speed_test '24934' 'Razzolink Inc.'
    speed_test '17846' 'Sonic.net Inc.'
    speed_test '15786' 'Sprint SanJose'
    speed_test '11899' 'Janus Networks'
}
speedtest() {
    clear
    # install speedtest-cli
    if  [ ! -e 'speedtest.py' ]; then
        echo -e "\n Downloading Speedtest.py ..."
        wget --no-check-certificate https://raw.github.com/sivel/speedtest-cli/master/speedtest.py > /dev/null 2>&1
    fi
    chmod a+rx speedtest.py
    echo -ne "\n speedtest.py 测速: \n"
    print_speedtest
    echo -ne "\n ${PURPLE}本机地址: ${PLAIN}$(wget -qO- -t1 -T2 ipv4.icanhazip.com)\n"
    echo -ne " ${PURPLE}系统时间: ${PLAIN}$(date +%Y-%m-%d" "%H:%M:%S)\n\n"
    pause
}
# iperf3测速
iperf3_test(){
    clear
#     if [ "${release}" == "centos" ];then
#         yum clean all >/dev/null 2>&1
#         rpm -qa | grep epel-release >/dev/null 2>&1 || (echo " Installing epel-release ..." && yum install epel-release -y >/dev/null 2>&1)
#     fi
#     sleep 3s
    if ! type iperf3 >/dev/null 2>&1 ;then
        echo " Installing iperf3 ..."
        if [ "${release}" == "centos" ];then
            yum install iperf3 -y >/dev/null 2>&1
        elif [ "${release}" == "ubuntu" ];then
            apt-get install iperf3 -y >/dev/null 2>&1
        fi
    fi
    echo -ne "\n iperf3 测速: \n"
    # echo -e " ${YELLOW}正在连接 iperf.he.net 节点...${PLAIN}"
    # iperf3 -c iperf.he.net | awk 'NR==1;NR==2;NR==15;NR==16;NR==17{print}'
    echo -e "\n ${YELLOW}正在连接 SV2 节点...${PLAIN}"
    iperf3 -c 142.4.97.233 | awk 'NR==1;NR==2;NR==15;NR==16;NR==17{print}'
    echo -e "\n ${YELLOW}正在连接 SV6 节点...${PLAIN}"
    iperf3 -c 107.148.199.113 | awk 'NR==1;NR==2;NR==15;NR==16;NR==17{print}'
    echo -ne "\n ${PURPLE}本机地址: ${PLAIN}$(wget -qO- -t1 -T2 ipv4.icanhazip.com)\n"
    echo -ne " ${PURPLE}系统时间: ${PLAIN}$(date +%Y-%m-%d" "%H:%M:%S)\n\n"
    pause
}
# ========================== 带宽测速 END ======================
# ##############################################################
# ===================== 查看修改SSH端口号 STA ==================
setsshport(){
    # 查询当前系统SSH端口号
    clear
    sshd_file="/etc/ssh/sshd_config"
    cp ${sshd_file} ${sshd_file}.bak
    if grep ^Port ${sshd_file} >/dev/null; then
        awk '/^Port/{print " 现在远程端口是:",$2}' ${sshd_file}
    else
        echo -e "\n 系统当前远程端口是: 22"
    fi
#    echo 
#    echo -e " 其它功能调试中...3秒后返回主菜单"
#    sleep 3s
#    start_menu
    # 设置远程端口号
    set sshport=0
    read -p " 请输入要设置的远程端口号，返回直接按Enter键: " sshport
    [[ ${sshport} == "" ]] && start_menu
    [[ ${sshport} == 0 ]] && start_menu
    if [ ${sshport} -gt 0 ] && [ ${sshport} -lt 65535 ];then
        # 修改ssh端口号
        echo -e " 正在设置远程端口号${sshport}..."
        sed -i 's/^Port/#Port/g' ${sshd_file}
        sed -i '' ${sshd_file}
        # 在匹配结果的第一行下方插入
        # sed -i "/^#Port/{s/$/\nPort ${sshport}/;:f;n;b f;}" ${sshd_file}
        # 在#Port 22这行上方插入
        sed -i "/^#Port 22$/i\Port ${sshport}" ${sshd_file}
        sleep 2s
        # 设置防火墙允许远程端口号
        if [ ${release} = "centos" ]; then
            if [ ${version1} -ge 7 ]; then
                firewall-cmd --state >/dev/null 2>&1 || systemctl start firewalld
                firewall-cmd --permanent --add-port=${sshport}/tcp >/dev/null 2>&1
                firewall-cmd --reload >/dev/null 2>&1
            fi
        elif [ ${release} = "ubuntu" ]; then
            if [ ${version1} -ge 16 ]; then
                ufw allow ${sshport} >/dev/null 2>&1
                ufw reload >/dev/null 2>&1
            fi
        else
            iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport ${sshport} -j ACCEPT >/dev/null 2>&1
            /etc/init.d/iptables restart >/dev/null 2>&1
        fi
        echo -e " 防火墙已允许端口号${sshport}/tcp..."
        # 重启sshd服务
        echo -e " 正在重启ssh服务..."
        if [ ${release} = "centos" ]; then
            if [ ${version1} -ge 7 ];then
                systemctl restart sshd >/dev/null 2>&1
            else
                service sshd restart >/dev/null 2>&1
            fi
        else
            systemctl restart ssh >/dev/null 2>&1
        fi
        sleep 2s
        echo -e " SSH服务已重启"
    else
        echo -e " ${Error}:输入有误，请重新输入！" && sleep 2s && setsshport
    fi
    pause
}
# ===================== 查看修改SSH端口号 END ==================
# ##############################################################
# ===================== 修改网卡名称为eth* STA =================
# CentOS7.x
chang2eth0(){
clear
if [[ ${release} = "centos" && ${version1} -eq 7 ]]; then
    # 修改网卡配置文件名称为eth格式
    timestamp=$(date '+%Y%m%d%H%M%S')
: '
        # 进入网卡配置文件路径
        cd /etc/sysconfig/network-scripts/
        [[ -d bak ]] || mkdir bak
        # n=需要修改的网卡名称的数量
        n=$[`ip a | grep "^[0-9]: " | wc -l`-1]
        # 将系统中所有网卡配置文件备份后修改为eth形式
        for ((i=0;i<$n;i++))
        do
            j=$i+2
            name=`ip a | grep "^[0-9]: " | tr -d : | awk "{if(NR==$j)print}" | awk '{print $2}'`
            cp ifcfg-${name} ./bak/ifcfg-${name}.bak.${timestamp}
            mv ifcfg-${name} ifcfg-eth$i
            sed -i "s/${name}/eth$i/g" ifcfg-eth$i
        done
'
    systemctl stop NetworkManager >/dev/null 2>&1;
    chkconfig NetworkManager off >/dev/null 2>&1;
    service NetworkManager stop >/dev/null 2>&1;
    which perl >/dev/null 2>&1 || yum -y install perl >/dev/null;
    if [ `which perl | wc -l` -ne 0 ];then
        let i=0;
        ip addr | grep "mtu 1500" | egrep -v bond | awk {'print $2'} | cut -d: -f1 | while read line;
        do
            if [ `ls /etc/sysconfig/network-scripts/ | grep $line | wc -l` -ne 0 ];then
               [[ -d /etc/sysconfig/network-scripts/bak ]] || mkdir /etc/sysconfig/network-scripts/bak;
                cp /etc/sysconfig/network-scripts/ifcfg-$line /etc/sysconfig/network-scripts/bak/ifcfg-${line}.bak.${timestamp};
                egrep -v 'HWADDR|NM_CONTROLLED' /etc/sysconfig/network-scripts/ifcfg-$line > /tmp/ifcfg-$line.new;
                cat /tmp/ifcfg-$line.new > /etc/sysconfig/network-scripts/ifcfg-$line;
                rm -f /tmp/ifcfg-$line.new;
                echo HWADDR=`ip addr | grep -A1 "mtu 1500" | grep -A1 $line | grep ether | awk {'print $2'}` >> /etc/sysconfig/network-scripts/ifcfg-$line;
                echo "HWADDR=`ip addr | grep -A1 "mtu 1500" | grep -A1 $line | grep ether | awk {'print $2'}` >> /etc/sysconfig/network-scripts/ifcfg-$line" >> /root/change-eth.log;
                echo "NM_CONTROLLED=no" >> /etc/sysconfig/network-scripts/ifcfg-$line;
                INTF=`echo eth$i`;
                mv /etc/sysconfig/network-scripts/ifcfg-$line /etc/sysconfig/network-scripts/ifcfg-$INTF;
                range_num=`ls /etc/sysconfig/network-scripts/ifcfg-$line-range* 2>null | wc -l`
                if [ ${range_num} -ne 0 ];then
                    for h in {0..${range_num}}; do mv "/etc/sysconfig/network-scripts/ifcfg-$line-range$h" "/etc/sysconfig/network-scripts/ifcfg-$INTF-range$h"; done
                fi
                perl -pi -e "s/$line/$INTF/" /etc/sysconfig/network-scripts/ifcfg-*;
                let "i=i+1";
            fi
        done
    else
        echo "perl installation failed, please try yum -y install perl first."
        exit 1
    fi
    # 备份并修改grub文件
    cp /etc/default/grub /etc/default/grub.bak.${timestamp}
    grep "net.ifnames=0 biosdevname=0" /etc/default/grub >/dev/null || sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0 /g' /etc/default/grub
    # 重新生成GRUB配置并更新内核参数
    grub2-mkconfig -o /boot/grub2/grub.cfg
    # 重启系统使配置生效
    echo -e "\n ${YELLOW}修改完成！系统将在5秒后 重启！${PLAIN}"
    echo -e " ${YELLOW}Ctrl+C 取消重启！！！${PLAIN}\c"
    sleep 5s
    reboot
else
    echo -e " ${Tip}:不支持当前操作系统，3秒后返回主菜单"
    sleep 3s
    start_menu
fi
# Centos 6-
}
# ===================== 修改网卡名称为eth* END =================
# ##############################################################
# ======================== 查看硬件配置 STA ====================
# 检测CPU、内存、硬盘
check_hard(){
    clear
    [ -x /usr/sbin/dmidecode ] || echo -e " Installing dmidecode..." && yum install dmidecode -y >/dev/null 2>&1
    # CPU型号名称
    name=$(grep name /proc/cpuinfo |cut -f2 -d: | tail -1 | sed -e 's/^[ \t]*//g' -e 's/  */ /g')
    # 物理CPU颗数
    physical_id=$(grep 'physical id' /proc/cpuinfo | sort -u | wc -l)
    # 单颗CPU核心数
    core_id=$(grep 'core id' /proc/cpuinfo | sort -u | wc -l)
    # 总线程数
    processor=$(grep 'processor' /proc/cpuinfo | sort -u | wc -l)
    echo -e "\n CPU型号名称  :  ${name}"
    echo -e " CPU颗数核心  :  ${physical_id} x ${core_id} = $[${core_id}*${physical_id}]"
    echo -e " CPU总线程数  :  ${processor}"
    # 物理内存条数及大小
    if grep -qEi "CentOS Linux release 8" /etc/redhat-release; then
        dmidecode -t memory | egrep ^\\s+Size.*GB$ | cut -f2 -d: | uniq -c | awk '{print $1,"x",$2,"=",$1*$2"G"}' | head -1 | sed -e 's/^[ \t]*/ MEM条数大小  :  /g'
    else
        dmidecode -t memory | egrep ^\\s+Size.*MB$ | cut -f2 -d: | uniq -c | awk '{print $1,"x",$2/1024,"=",$1*$2/1024"G"}' | head -1 | sed -e 's/^[ \t]*/ MEM条数大小  :  /g'
    fi
    # 所有硬盘名称、容量及类型
    lsblk -d -o name,size,rota --nohead | awk '$1~/sd|vd/{if ($3=="0") printf " DSK容量类型  :  %-4s%-7s%-2s\n",$1,$2,"SSD";else printf " DSK容量类型  :  %-4s%-7s%-2s\n",$1,$2,"HDD（仅限硬盘直连主板的物理服务器）"}'
    # 开启状态的网卡名称及其配置的主IP
    ip a | grep -A 2 "state UP" | awk 'NR%2{printf "%s",$2}' | sed 's/^[ \t]*/ NIC名称及IP  :  /g'
    pause "\n\n ${Tip} 以上信息仅供参考！！！\n"
}
# ======================== 查看硬件配置 END ====================
# ##############################################################
# ====================== 检查Linux系统版本 STA =================
# 检查Linux系统
check_sys(){
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif cat /etc/issue | grep -qEi "debian"; then
        release="debian"
    elif cat /etc/issue | grep -qEi "ubuntu"; then
        release="ubuntu"
    elif cat /etc/issue | grep -qEi "centos|red hat|redhat"; then
        release="centos"
    elif cat /proc/version | grep -qEi "debian"; then
        release="debian"
    elif cat /proc/version | grep -qEi "ubuntu"; then
        release="ubuntu"
    elif cat /proc/version | grep -qEi "centos|red hat|redhat"; then
        release="centos"
    fi
}
# 检查Linux版本
check_version(){
    if [[ -s /etc/redhat-release ]]; then
        version=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1-2`
        version1=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1`
    else
        version=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1-2`
        version1=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1`
    fi
    bit=`uname -m`
    if [[ ${bit} = "x86_64" ]]; then
        bit="x64"
    else
        bit="x32"
    fi
}
# ====================== 检查Linux系统版本 END =================
# ##############################################################
# ========================== I/O性能测试 STA ===================
io_test() {
    (LANG=C dd if=/dev/zero of=test_file_$$ bs=512K count=$1 conv=fdatasync && rm -f test_file_$$ ) 2>&1 | awk -F, '{io=$NF} END { print io}' | sed 's/^[ \t]*//;s/[ \t]*$//'
}
freedisk() {
    freespace=$( df -m . | awk 'NR==2 {print $4}' )
    if [[ $freespace == "" ]]; then
        $freespace=$( df -m . | awk 'NR==3 {print $3}' )
    fi
    if [[ $freespace -gt 1024 ]]; then
        printf "%s" $((1024*2))
    elif [[ $freespace -gt 512 ]]; then
        printf "%s" $((512*2))
    elif [[ $freespace -gt 256 ]]; then
        printf "%s" $((256*2))
    elif [[ $freespace -gt 128 ]]; then
        printf "%s" $((128*2))
    else
        printf "1"
    fi
}
print_io() {
    if [[ $1 == "fast" ]]; then
        writemb=$((128*2))
    else
        writemb=$(freedisk)
    fi
    
    writemb_size="$(( writemb / 2 ))MB"
    if [[ $writemb_size == "1024MB" ]]; then
        writemb_size="1.0GB"
    fi
    if [[ $writemb != "1" ]]; then
        echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
        io1=$( io_test $writemb )
        echo -e "${YELLOW}$io1${PLAIN}" | tee -a $log
        echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
        io2=$( io_test $writemb )
        echo -e "${YELLOW}$io2${PLAIN}" | tee -a $log
        echo -n " I/O Speed( $writemb_size )   : " | tee -a $log
        io3=$( io_test $writemb )
        echo -e "${YELLOW}$io3${PLAIN}" | tee -a $log
        ioraw1=$( echo $io1 | awk 'NR==1 {print $1}' )
        [ "`echo $io1 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw1=$( awk 'BEGIN{print '$ioraw1' * 1024}' )
        ioraw2=$( echo $io2 | awk 'NR==1 {print $1}' )
        [ "`echo $io2 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw2=$( awk 'BEGIN{print '$ioraw2' * 1024}' )
        ioraw3=$( echo $io3 | awk 'NR==1 {print $1}' )
        [ "`echo $io3 | awk 'NR==1 {print $2}'`" == "GB/s" ] && ioraw3=$( awk 'BEGIN{print '$ioraw3' * 1024}' )
        ioall=$( awk 'BEGIN{print '$ioraw1' + '$ioraw2' + '$ioraw3'}' )
        ioavg=$( awk 'BEGIN{printf "%.1f", '$ioall' / 3}' )
        echo -e " Average I/O Speed    : ${YELLOW}$ioavg MB/s${PLAIN}" | tee -a $log
    else
        echo -e " ${RED}Not enough space!${PLAIN}"
    fi
    pause
}
# ========================== I/O性能测试 END ===================
# ##############################################################
# ====================== 使用说明及开始菜单 STA ================
# 脚本功能及使用说明
instructions(){
    clear
    echo && echo -e "
 ${Info}本脚本相关功能及使用说明：
 ${GREEN}1.${PLAIN} IP配置仅支持CentOS和Ubuntu;
    仅适用于网关IP为IP段最后一位可用IP的环境下;
 ${GREEN}2.${PLAIN} 整段IP配置仅支持/24-/29,(连续IP包含整段IP);
 ${GREEN}3.${PLAIN} CentOS重启网络服务时，可能存在执行命令超时,
    不用重复执行，可以使用ip a查看配置已经在生效即可;
    Ubuntu个别版本重启网络可能会报错，直接reboot可生效;
 ${GREEN}4.${PLAIN} speedtest测速，会对默认节点及圣何塞的几个节点进行测速;
 ${GREEN}5.${PLAIN} iperf3一般用于10G带宽测速，外网节点iperf.he.net，内网节点192.74.245.170;
 ${GREEN}6.${PLAIN} 查看修改SSH端口号功能，目前只支持查看，修改功能开发中;
 ${GREEN}7.${PLAIN} 修改网卡名称为eth暂只支持CentOS7.x;
 ${GREEN}8.${PLAIN} 所有涉及到修改配置文件的操作,
    都会在对应目录创建bak目录,
    并备份原文件到bak目录;
 ${GREEN}9.${PLAIN} 硬件信息仅供参考!!!
${SKYBLUE} 如使用过程中遇到BGU或建议，请及时反馈，谢谢！！！${PLAIN}
 " && echo
    pause
}
# 开始菜单
start_menu(){
    clear
    echo && echo -e " ${SKYBLUE_B}Linux系统 配置工具${PLAIN} ${RED}[v${sh_ver}]${PLAIN}
     -- ${PURPLE_F}By Shihua${PLAIN} --  
${SKYBLUE}————————IP配置————————————${PLAIN}
 ${GREEN}1.${PLAIN} 连续IP配置
 ${GREEN}2.${PLAIN} 整段IP配置 
 ${GREEN}3.${PLAIN} 重启网络服务
${SKYBLUE}————————带宽测试——————————${PLAIN}
 ${GREEN}4.${PLAIN} speedtest测速
 ${GREEN}5.${PLAIN} iperf3测速
${SKYBLUE}————————其它配置——————————${PLAIN}
 ${GREEN}6.${PLAIN} 查看修改SSH端口号
 ${GREEN}7.${PLAIN} 修改网卡名称为eth
 ${GREEN}8.${PLAIN} 查看硬件配置
 ${GREEN}9.${PLAIN} 查看帮助
 ${GREEN}q.${PLAIN} 退出脚本
${SKYBLUE}——————————————————————————${PLAIN}
 ${RED}★★${PLAIN} 使用说明：
 ${RED}1.${PLAIN} 在任何等待输入界面，输入0可返回本菜单
 ${RED}2.${PLAIN} IP配置仅适用于网关是IP段最后一个可用IP" && echo
    echo -e " 当前系统版本：${YELLOW}"${release} ${version} ${bit}"${PLAIN}\n"
    xzcz
}
xzcz(){
    read -p " 请选择您的操作[1-9|q]:" num
    case "$num" in
        0)
            start_menu
            ;;
        [1-2])
            get_nic_name
            ;;
        3)
            restart_network
            ;;
        4)
            speedtest
            ;;
        5)
            iperf3_test
            ;;
        6)
            setsshport
            ;;
        7)
            chang2eth0
            ;;
        8)
            check_hard
            ;;
        9)
            instructions
            ;;
        m|M)
            more_functions
            ;;
        q|Q)
            cancel
            exit
            ;;
        *)
            echo -e " ${Error}:输入有误，请重新输入！"
            xzcz
            ;;
    esac
}
# ====================== 使用说明及开始菜单 END ================
# ##############################################################
# ========================= 更多功能菜单 STA ===================
more_functions() {
    clear
    echo && echo -e " ${SKYBLUE_B}Linux系统 配置工具${PLAIN} ${RED}[v${sh_ver}]${PLAIN}
     -- ${PURPLE_F}By Shihua${PLAIN} --  
${SKYBLUE}————————更多功能————————————${PLAIN}
 ${GREEN}a.${PLAIN} CentOS安装91云锐速
 ${GREEN}b.${PLAIN} 硬盘I/O普通测试
 ${GREEN}c.${PLAIN} 硬盘I/O快速测试
 ${GREEN}d.${PLAIN} 下载sping.sh脚本
 ${GREEN}0.${PLAIN} 返回菜单
 ${GREEN}q.${PLAIN} 退出脚本
${SKYBLUE}——————————————————————————${PLAIN}" && echo
    echo -e " 当前系统版本：${YELLOW}"${release} ${version} ${bit}"${PLAIN}\n"
    xzcz_m
}
xzcz_m() {
    read -p " 请选择您的操作:" letter
    case "$letter" in
        0)
            start_menu
            ;;
        a|A)
            install_91yun_serverspeeder
            ;;
        b|B)
            print_io
            ;;
        c|C)
            print_io fast
            ;;
        d|D)
            wget http://www.saiwa.cf/sping.sh
            exit 0
            ;;
        q|Q)
            cancel
            exit 0
            ;;
        *)
            echo -e " ${Error}:输入有误，请重新输入！"
            xzcz_m
            ;;
    esac
}
install_91yun_serverspeeder(){
: '
echo -e " 功能开发中···"
sleep 3s
start_menu
'
    echo -e " ${Tip}:安装后会自动重启服务器，请确认后按回车开始安装！\c" && read y
    if [ ${y} -eq 0 ] 2>/dev/null ; then
       start_menu
    else
       if [[ ${release} = "centos" && ${version1} -eq 7 ]]; then
           yum install net-tools -y >/dev/null 2>&1
           wget -N --no-check-certificate https://github.com/91yun/serverspeeder/raw/master/serverspeeder.sh && bash serverspeeder.sh
           echo "service serverSpeeder start" >> /etc/rc.d/rc.local && chmod +x /etc/rc.d/rc.local
           reboot
       else
           echo -e " ${Tip}:不支持当前操作系统，3秒后返回主菜单"
           sleep 3s
           start_menu
        fi
    fi
}
# ========================= 更多功能菜单 END ===================
# ##############################################################
# ===================== 执行检测系统运行脚本 STA ===============
# 开始检查系统版本，脚本仅支持CentOS、Ubuntu、Debian系统
self=`ls $0`
check_sys
check_version
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e " ${Error} 本脚本不支持当前系统 ${release} !" && exit 1
# 运行开始菜单
start_menu
# ===================== 执行检测系统运行脚本 END ===============
# The END
