#!/bin/bash

# 校验端口是否占用
function checkPort() {
    checkPortProcess $1
    if [ $RESULT -gt 0 ] ; then
        RESULT=1
    else
        RESULT=0
    fi
}

# 通过端口杀死进程
function killByPort() {
    echoInfo "trying to kill process by port \"$1\""
    if [ $1 -gt 0 ] ; then
        checkPortProcess $1
        if [ $RESULT -gt 0 ] ; then
            echoInfo "process is running on port $1, try kill it..."
            getPortProcessId $1
            kill -9 $RESULT
        else
            echoInfo "process is not running!"
        fi
    fi
}

# 记录日志文件
function _logfile() {
    if [ ! -d ${home}/log ] ; then
        mkdir -p ${home}/log
    fi
    echo $1 >> ${home}/log/startup.log
}

# 获取端口进程id
function getPortProcessId() {
    RESULT=`netstat -nlp | grep $1 | awk '{print $7}' | awk -F '/' '{print $1}'`
}

# 校验端口是否被占用
function checkPortProcess() {
    RESULT=`netstat -nlp | grep $1 | awk "{print $7}" | wc -l`
}

# 记录info日志文件
function info() {
    TIME=`date '+%Y-%m-%d %H:%M:%S'`
    echo -e "\033[34m ${TIME}\033[1m \033[32m [INFO] \033[0m $1"
    _logfile "${TIME} [INFO] $1"
}

function error() {
    TIME=`date '+%Y-%m-%d %H:%M:%S'`
    echo -e "\033[34m ${TIME}\033[1m \033[31m [ERROR] \033[0m $1"
    _logfile "${TIME} [INFO] $1"
}

# 循环校验进程是否启动，直到启动成功
function checkProcess(){
    RUNNING=0
    while [ $RUNNING -eq 0 ]
    do
        checkPort $2
        RUNNING=$RESULT
        sleep 1

        if [ $RUNNING -eq 0 ] ; then
            info "waiting for $1 starting ..."
        fi
    done

    info "$1 started !"
}

# 打印日志，有颜色
function echoInfo(){
    echo -e " \033[1m \033[32m $1 \033[0m"
}

# 打印日志，有颜色
function echoError(){
    echo -e " \033[1m \033[31m $1 \033[0m"
}


function isRootUser() {
    RESULT=1
    if [ $UID -ne 0 ]; then
        RESULT=0
    fi
}

function mustRootUser() {
    isRootUser
    if [ $RESULT -eq 0 ] ; then
        echoError "please switch to root user"
        exit
    fi
}

# 将当前用户添加到docker操作组
function addUserToDocker(){
    mustRootUser
    gpasswd -a $1 docker    
    newgrp docker   
    systemctl restart docker
}

# 安装docker
function dockerInstall(){
    mustRootUser
    # curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    curl -sSL https://get.daocloud.io/docker | sh
    changeDockerMirror
}
function dockerComposeInstall(){
    mustRootUser
    apt-get update
    apt-get install docker-compose
    # curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose & chmod +x /usr/local/bin/docker-compose
    # curl -sSL https://get.daocloud.io/docker | sh
}
# 更新docker仓库
function changeDockerMirror(){
    mustRootUser
    FILE="/etc/docker/daemon.json"
    if [ -f $FILE ]; then
        echoError "docker配置文件已存在，停止改变docker镜像中心操作"
    else
        echo -e "{
        \"registry-mirrors\":[\"http://hub-mirror.c.163.com\"]\n}" > /etc/docker/daemon.json
        systemctl restart docker
    fi
}

# 安装常用的命令
function commandInit() {
    mustRootUser
    apt-get install -y curl lrzsz unzip procps nfs-common vim socat conntrack ebtables ipset sudo
}


# 安装k3s
function k3sInstall(){
    mustRootUser
    curl -sfL https://get.k3s.io | sh -
}

function init() {
    mustRootUser
    info "更改为上海时区"
    timedatectl set-timezone Asia/Shanghai
    info "安装常用命令工具：curl lrzsz unzip procps nfs-common vim socat conntrack ebtables ipset sudo"
    commandInit
}

function readInput() {
    if [ "$1" = "" ]; then
        echoError "消息为空"
        exit
    fi
    while :; do echo
      read -e -p "$1" RESULT
      if [  "$RESULT" = ""  ]; then
        echo "输入内容不能为空"
      else
        break
      fi
    done
}

function backup() {
    cp $1 $1.bak
}

function permitRootRemoteLogin() {
    mustRootUser
    FILE="/etc/ssh/sshd_config"
    if [[ `cat $FILE | grep 'PermitRootLogin yes' | wc -l` > 0 ]]; then
        echoError '已开启root远程登录'
    else
        backup $FILE
        sed -i '$a PermitRootLogin yes' $FILE
        if [[ `cat $FILE | grep 'PermitRootLogin yes' | wc -l` > 0 ]]; then
            systemctl restart sshd
            echoInfo '开启root远程登录操作成功'
        fi
    fi
}

function permitDockerRemoteConnect() {
    mustRootUser
    FILE="/lib/systemd/system/docker.service"
    if [[ `sed -n '/ExecStart/p' $FILE | grep 'tcp://0.0.0.0:2375' | wc -l` > 0 ]]; then
        echoError '已开启docker远程连接'
    else
        backup $FILE
        sed -r -i 's#(^ExecStart.*sock)#\1 -H tcp://0.0.0.0:2375#g' $FILE
        if [[ `sed -n '/ExecStart/p' $FILE | grep 'tcp://0.0.0.0:2375' | wc -l` > 0 ]]; then
            #systemctl daemon-reload
            echoInfo '开启docker远程连接操作成功'
        else
           echoError '修改文件失败'
        fi 
    fi
}


function addSudoer() {
    mustRootUser
    FILE='/etc/sudoers.d/custom'
    if [ ! -f $FILE ]; then
        touch $FILE
    fi
    readInput '请输入用户名：'
    if [[ `cat $FILE | grep $RESULT | wc -l` > 0 ]]; then
        echoError "已将 $RESULT 加入超级管理员"
    else
        cat >> $FILE <<EOF
$RESULT    ALL=(ALL:ALL) ALL
EOF
        if [[ `cat $FILE | grep $RESULT | wc -l` > 0 ]]; then
            echoInfo "添加 $RESULT 进入超级管理员成功"
        fi
    fi
    
}

#         `cat >> $FILE <<"EOF"
# TEMP    ALL=(ALL:ALL) ALL
# EOF` | sed -r -i "s#TEMP#$RESULT#" custom

function handVimCopy() {
    FILE="$HOME/.vimrc"
    if [ -f $FILE ]; then
        echoError "已配置vim拷贝问题"
    else
        touch $FILE
        cat >> $FILE <<EOF
if has("syntax")  
  syntax on
endif
EOF
        if [ -f $FILE ]; then
            echoInfo '处理vim拷贝问题成功'
        fi
    fi
}


function processAlias() {
    FILE='.bashrc'
    cd ~
    if [ ! -f $FILE ]; then
        touch $FILE
    else
        declare -A aliasMap
        # 镜像对应的开放的端口
        aliasMap["la="]='alias la="ls -al --color=auto"'
        aliasMap["ll="]='alias ll="ls -l --color=auto"'
        aliasMap["dockerc"]='alias dockerc="docker-compose"'
        aliasMap["dockerma"]='alias dockerma="docker rm -v $(docker ps -aq -f status=exited)"'
        aliasMap["dockerin"]='function dockerin() {
    docker exec -it $1 /bin/bash
}'
        aliasMap["k="]='alias k="kubectl"'
        aliasMap["kdp="]='alias kdp="kubectl describe po"'
        aliasMap["kds="]='alias kds="kubectl describe svc"'
        aliasMap["kcd="]='alias kcd="kubectl config set-context --current --namespace"'
        aliasMap["kt="]='alias kt="kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath=\"{.secrets[0].name}\") -o go-template=\"{{.data.token | base64decode}}\""'
        aliasMap["kin"]='function kin() {
    kubectl exec -it $1 -- /bin/sh
}'      
        for key in ${!aliasMap[@]}
        do
            if [[ `sed 's/^[ \t]*//g' $FILE | sed -n '/^[^#]/p' | grep $key | wc -l` > 0 ]];then
                    echoError "${aliasMap[$key]} 已存在"
            else
                if [ "$key" = "la=" ] || [ "$key" = "ll=" ];then
                   `cat >> $FILE <<EOF
${aliasMap[$key]}
EOF`
                else
                    if [[ `echo "${aliasMap[$key]}" | grep "docker" | wc -l` > 0 ]];then
                        if [[ `command -v docker | wc -l` = 0 ]];then
                            echoError "docker运行环境不存在，相关别名设置跳过"
                        else
                            `cat >> $FILE <<EOF
${aliasMap[$key]}
EOF`
                        fi
                    elif [[ `echo "${aliasMap[$key]}" | grep "kubectl" | wc -l` > 0 ]]; then
                        #statements
                        if [[ `command -v kubectl | wc -l` = 0 ]];then
                            echoError "kubenetes运行环境不存在，相关别名设置跳过"
                        else
                            `cat >> $FILE <<EOF
${aliasMap[$key]}
EOF`
                        fi
                    fi
                fi
                # 先替换空格和制表符，然后在判断是否以#开头
                if [[ `sed 's/^[ \t]*//g' $FILE | sed -n '/^[^#]/p' | grep $key | wc -l` > 0 ]];then
                    echoInfo "${aliasMap[$key]} 添加成功"
                fi
            fi
        done
    fi
    source ~/.bashrc
}

function comand() {
    while :; do echo
        printf "
#######################################################################
                               自用安装工具                          
#######################################################################
"
        echo -e '请选择操作'
        echo -e "\t1. 系统初始化（安装常用命令，更改系统时区）"
        echo -e "\t2. 安装docker"
        echo -e "\t3. 安装k3s"
        echo -e "\t4. 安装docker-compose"
        echo -e "\t5. 添加用户到docker"
        echo -e "\t6. root开启远程访问"
        echo -e "\t7. docker开启远程连接"
        echo -e "\t8. 添加sudo用户"
        echo -e "\t9. 处理vim拷贝问题"
        echo -e "\t10. 处理别名问题"
        echo -e "\t99. 退出"
        read -e -p "请输入操作编号：" option
        case "$option" in
        1)
            init
            ;;
        2)
            dockerInstall
            ;;
        3)
            k3sInstall
            ;;
        4)
            dockerComposeInstall
            ;;
        5)
            readInput '请输入用户名：'
            addUserToDocker $RESULT
            ;;
        6)
            permitRootRemoteLogin
            ;;
        7)
            permitDockerRemoteConnect
            ;;
        8)
            addSudoer
            ;;
        9)
            handVimCopy
            ;;
        10)
            processAlias
            ;;
        99)
            clear
            break
            ;;
        *)
            echoError '输入参数错误，请重试'
        esac
    done 
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
        echo -e '请选择操作'
        echo -e "\t1. 更改系统ip"
        echo -e "\t9. 退出"
        read -e -p "请输入操作编号：" option
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

while :; do echo
    echo '请选择操作:'
    echo -e "\t1. 操作"
    echo -e "\t2. 帮助"
    read -e -p "请输入操作编号：" option
    case "$option" in
        1)  
            clear
            comand
            ;;
        2)
            clear
            tips
            ;;
        *)
            echoError '输入参数错误，请重试'
        esac
done