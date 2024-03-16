#!/bin/bash

# 打印日志，有颜色
function echoInfo(){
    echo -e " \033[1m \033[32m $1 \033[0m"
}
function showChangeIpTips() {
    isDebian=`cat "/proc/version" | grep 'debian' | wc -l`
    if [[ $isDebian > 0 ]]; then
        echoInfo "
编辑： /etc/network/interfaces
示例：
iface ens192 inet static
address 10.1.1.10
netmask 255.255.255.0
gateway 10.1.1.1
dns-nameservers 10.1.1.1
    "
    else
        isUbuntu=`cat "/proc/version" | grep 'ubuntu' | wc -l`
        if [[ $isUbuntu > 0 ]]; then
        echoInfo "
编辑 /etc/netplan 目录下面的yml文件，视实际情况而定
示例：
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    enp0s5:   # 网卡名称
      dhcp4: no     # 关闭dhcp
      dhcp6: no
      addresses: [10.1.1.10/24]  # 静态ip
      gateway4: 10.1.1.1     # 网关
      nameservers:
        addresses: [10.1.1.1]
    "
        else
            echoInfo "
1、修改网卡配置
文件在 /etc/sysconfig/network-scripts/ifcfg-eth0
DEVICE=eth0         #描述网卡对应的设备别名，例如ifcfg-eth0的文件中它为eth0
BOOTPROTO=static       #设置网卡获得ip地址的方式，可能的选项为static，dhcp或bootp，分别对应静态指定的 ip地址，通过dhcp协议获得的ip地址，通过bootp协议获得的ip地址
BROADCAST=192.168.0.255   #对应的子网广播地址
HWADDR=00:07:E9:05:E8:B4   #对应的网卡物理地址
IPADDR=12.168.0.33      #如果设置网卡获得 ip地址的方式为静态指定，此字段就指定了网卡对应的ip地址
NETMASK=255.255.255.0    #网卡对应的网络掩码
NETWORK=192.168.0.0     #网卡对应的网络地址
2、修改网关配置
文件在 /etc/sysconfig/network
NETWORKING=yes     #(表示系统是否使用网络，一般设置为yes。如果设为no，则不能使用网络，而且很多系统服务程序将无法启动)
HOSTNAME=centos    #(设置本机的主机名，这里设置的主机名要和/etc/hosts中设置的主机名对应)
GATEWAY=192.168.0.1  #(设置本机连接的网关的IP地址。)
3、修改DNS配置
文件在 /etc/resolv.conf

    "
        fi
    fi
}

function tips() {
   while :; do echo
        printf "
#######################################################################
                               帮助
#######################################################################
"
        echo  '请选择操作'
        echo  "1. 更改系统ip"
        echo  "9. 退出"
        read  -p "请输入操作编号：" option
        case "$option" in
        1)
            showChangeIpTips
            ;;
        9)
            clear
            break
            ;;
        *)
            echoError '输入参数错误，请重试'
        esac

    done
}

tips