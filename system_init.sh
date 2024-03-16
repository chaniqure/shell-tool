#!/bin/bash
# 初始化系统相关依赖
function isRootUser() {
    RESULT=1
    if [ $UID -ne 0 ]; then
        RESULT=0
    fi
}

# 判断当前用户是否是root用户，不是root用户就退出脚本执行
function mustRootUser() {
    isRootUser
    if [ $RESULT -eq 0 ] ; then
        echoError "please switch to root user"
        exit
    fi
}

# 打印日志，有颜色
function echoInfo(){
    echo -e " \033[1m \033[32m $1 \033[0m"
}

# 打印日志，有颜色
function echoError(){
    echo -e " \033[1m \033[31m $1 \033[0m"
}

# 用于读取用户输入
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

# 将当前用户添加到docker操作组
function addUserToDocker(){
    mustRootUser
    gpasswd -a $1 docker
    newgrp docker
    systemctl restart docker
}

# 基础初始化
function baseInit() {
    mustRootUser
    info "更改为上海时区"
    timedatectl set-timezone Asia/Shanghai
    info "安装常用命令工具：curl lrzsz unzip procps nfs-common vim socat conntrack ebtables ipset sudo"
    commandInit
}

# 安装k3s
function k3sInstall(){
    mustRootUser
    curl -sfL https://get.k3s.io | sh -
}

# 安装常用的命令
function commandInit() {
    mustRootUser
    apt-get install -y curl lrzsz unzip procps nfs-common vim socat conntrack ebtables ipset sudo
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

function command() {
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
        read -p "请输入操作编号：" option
        case "$option" in
        1)
            baseInit
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

command