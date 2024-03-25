#!/bin/bash

# 将当前用户添加到docker操作组
function add_user_to_docker(){
    must_root_user
    gpasswd -a $1 docker
    newgrp docker
    systemctl restart docker
}

# 基础初始化
function base_init() {
    must_root_user
    info "更改为上海时区"
    timedatectl set-timezone Asia/Shanghai
    info "安装常用命令工具：curl lrzsz unzip procps nfs-common vim socat conntrack ebtables ipset sudo"
    command_init
}

# 安装k3s
function k3s_install(){
    must_root_user
    curl -sfL https://get.k3s.io | sh -
}

# 安装常用的命令
function command_init() {
    must_root_user
    apt-get install -y curl lrzsz unzip procps nfs-common vim socat conntrack ebtables ipset sudo
}

# 安装docker
function docker_install(){
    must_root_user
    # curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
#     curl -sSL https://get.daocloud.io/docker | sh
    if ! which docker; then
        info "docker 未安装，脚本尝试自动安装..."
        wget -qO- get.docker.com | bash
        if which docker; then
            info "docker 安装成功！"
        else
            error "docker 安装失败，请手动安装！"
            exit 1
        fi
    fi
    change_docker_mirror
}
function docker_compose_install(){
    must_root_user
    apt-get update
    apt-get install docker-compose
    # curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose & chmod +x /usr/local/bin/docker-compose
    # curl -sSL https://get.daocloud.io/docker | sh
}
# 更新docker仓库
function change_docker_mirror(){
    must_root_user
    FILE="/etc/docker/daemon.json"
    if [ -f $FILE ]; then
        error "docker配置文件已存在，停止改变docker镜像中心操作"
    else
        echo -e "{
        \"registry-mirrors\":[\"http://hub-mirror.c.163.com\"]\n}" > /etc/docker/daemon.json
        systemctl restart docker
    fi
}

function permit_root_remote_login() {
    must_root_user
    FILE="/etc/ssh/sshd_config"
    if [[ `cat $FILE | grep 'PermitRootLogin yes' | wc -l` > 0 ]]; then
        error '已开启root远程登录'
    else
        backup $FILE
        sed -i '$a PermitRootLogin yes' $FILE
        if [[ `cat $FILE | grep 'PermitRootLogin yes' | wc -l` > 0 ]]; then
            systemctl restart sshd
            info '开启root远程登录操作成功'
        fi
    fi
}

function permit_docker_remote_connect() {
    must_root_user
    FILE="/lib/systemd/system/docker.service"
    if [[ `sed -n '/ExecStart/p' $FILE | grep 'tcp://0.0.0.0:2375' | wc -l` > 0 ]]; then
        error '已开启docker远程连接'
    else
        backup $FILE
        sed -r -i 's#(^ExecStart.*sock)#\1 -H tcp://0.0.0.0:2375#g' $FILE
        if [[ `sed -n '/ExecStart/p' $FILE | grep 'tcp://0.0.0.0:2375' | wc -l` > 0 ]]; then
            #systemctl daemon-reload
            info '开启docker远程连接操作成功'
        else
           error '修改文件失败'
        fi
    fi
}


function add_sudoer() {
    must_root_user
    FILE='/etc/sudoers.d/custom'
    if [ ! -f $FILE ]; then
        touch $FILE
    fi
    require_input '请输入用户名：'
    if [[ `cat $FILE | grep $RESULT | wc -l` > 0 ]]; then
        error "已将 $RESULT 加入超级管理员"
    else
        cat >> $FILE <<EOF
$RESULT    ALL=(ALL:ALL) ALL
EOF
        if [[ `cat $FILE | grep $RESULT | wc -l` > 0 ]]; then
            info "添加 $RESULT 进入超级管理员成功"
        fi
    fi

}

#         `cat >> $FILE <<"EOF"
# TEMP    ALL=(ALL:ALL) ALL
# EOF` | sed -r -i "s#TEMP#$RESULT#" custom

function hand_vim_copy() {
    FILE="$HOME/.vimrc"
    if [ -f $FILE ]; then
        error "已配置vim拷贝问题"
    else
        touch $FILE
        cat >> $FILE <<EOF
if has("syntax")
  syntax on
endif
EOF
        if [ -f $FILE ]; then
            info '处理vim拷贝问题成功'
        fi
    fi
}


function process_alias() {
    FILE='.bashrc'
    cd ~
    if [ ! -f $FILE ]; then
        touch $FILE
    else
        declare -A alias_map
        # 镜像对应的开放的端口
        alias_map["la="]='alias la="ls -al --color=auto"'
        alias_map["ll="]='alias ll="ls -l --color=auto"'
        alias_map["dockerc"]='alias dockerc="docker-compose"'
        alias_map["dockerma"]='alias dockerma="docker rm -v $(docker ps -aq -f status=exited)"'
        alias_map["dockerin"]='function dockerin() {
    docker exec -it $1 /bin/bash
}'
        alias_map["k="]='alias k="kubectl"'
        alias_map["kdp="]='alias kdp="kubectl describe po"'
        alias_map["kds="]='alias kds="kubectl describe svc"'
        alias_map["kcd="]='alias kcd="kubectl config set-context --current --namespace"'
        alias_map["kt="]='alias kt="kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath=\"{.secrets[0].name}\") -o go-template=\"{{.data.token | base64decode}}\""'
        alias_map["kin"]='function kin() {
    kubectl exec -it $1 -- /bin/sh
}'
        for key in ${!alias_map[@]}
        do
            if [[ `sed 's/^[ \t]*//g' $FILE | sed -n '/^[^#]/p' | grep $key | wc -l` > 0 ]];then
                    error "${alias_map[$key]} 已存在"
            else
                if [ "$key" = "la=" ] || [ "$key" = "ll=" ];then
                   `cat >> $FILE <<EOF
${alias_map[$key]}
EOF`
                else
                    if [[ `echo "${alias_map[$key]}" | grep "docker" | wc -l` > 0 ]];then
                        if [[ `command -v docker | wc -l` = 0 ]];then
                            error "docker运行环境不存在，相关别名设置跳过"
                        else
                            `cat >> $FILE <<EOF
${alias_map[$key]}
EOF`
                        fi
                    elif [[ `echo "${alias_map[$key]}" | grep "kubectl" | wc -l` > 0 ]]; then
                        #statements
                        if [[ `command -v kubectl | wc -l` = 0 ]];then
                            error "kubenetes运行环境不存在，相关别名设置跳过"
                        else
                            `cat >> $FILE <<EOF
${alias_map[$key]}
EOF`
                        fi
                    fi
                fi
                # 先替换空格和制表符，然后在判断是否以#开头
                if [[ `sed 's/^[ \t]*//g' $FILE | sed -n '/^[^#]/p' | grep $key | wc -l` > 0 ]];then
                    info "${alias_map[$key]} 添加成功"
                fi
            fi
        done
    fi
    info '添加别名完成'
    # source ~/.bashrc
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
            base_init
            ;;
        2)
            docker_install
            ;;
        3)
            k3s_install
            ;;
        4)
            docker_compose_install
            ;;
        5)
            require_input '请输入用户名：'
            add_user_to_docker $RESULT
            ;;
        6)
            permit_root_remote_login
            ;;
        7)
            permit_docker_remote_connect
            ;;
        8)
            add_sudoer
            ;;
        9)
            hand_vim_copy
            ;;
        10)
            process_alias
            ;;
        99)
            clear
            break
            ;;
        *)
            error '输入参数错误，请重试'
        esac
    done
}

command