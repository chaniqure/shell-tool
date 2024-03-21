#!/bin/bash

# 记录info日志文件
function INFO() {
    TIME=`date '+%Y-%m-%d %H:%M:%S'`
    echo -e "\033[34m ${TIME}\033[1m \033[32m [INFO] \033[0m $1"
    _logfile "${TIME} [INFO] $1"
}

# 记录warn日志文件
function WARN() {
    TIME=`date '+%Y-%m-%d %H:%M:%S'`
    echo -e "\033[34m ${TIME}\033[1m \033[1;31;33m [WARN] \033[0m $1"
    _logfile "${TIME} [INFO] $1"
}
# 记录error日志文件
function ERROR() {
    TIME=`date '+%Y-%m-%d %H:%M:%S'`
    echo -e "\033[34m ${TIME}\033[1m \033[31m [ERROR] \033[0m $1"
    _logfile "${TIME} [INFO] $1"
}

# 记录日志文件
function _logfile() {
    if [ ! -d ${home}/log ] ; then
        mkdir -p ${home}/log
    fi
    echo $1 >> ${home}/log/startup.log
}

# 打印日志，有颜色
function info(){
    echo -e " \033[1m \033[32m $1 \033[0m"
}
# 打印日志，有颜色
function warn(){
    echo -e " \033[1;31;33m $1 \033[0m"
}

# 打印日志，有颜色
function error(){
    echo -e " \033[1m \033[31m $1 \033[0m"
}

# 校验端口是否占用
function check_port() {
    check_port_process $1
    if [ $RESULT -gt 0 ] ; then
        RESULT=1
    else
        RESULT=0
    fi
}

# 循环校验进程是否启动，直到启动成功
function check_process(){
    RUNNING=0
    while [ $RUNNING -eq 0 ]
    do
        check_port $2
        RUNNING=$RESULT
        sleep 1

        if [ $RUNNING -eq 0 ] ; then
            info "waiting for $1 starting ..."
        fi
    done

    info "$1 started !"
}

# 通过端口杀死进程
function kill_by_port() {
    echoInfo "trying to kill process by port \"$1\""
    if [ $1 -gt 0 ] ; then
        check_port_process $1
        if [ $RESULT -gt 0 ] ; then
            echoInfo "process is running on port $1, try kill it..."
            get_port_process_id $1
            kill -9 $RESULT
        else
            echoInfo "process is not running!"
        fi
    fi
}

# 获取端口进程id
function get_port_process_id() {
    RESULT=`netstat -nlp | grep $1 | awk '{print $7}' | awk -F '/' '{print $1}'`
}

# 校验端口是否被占用
function check_port_process() {
    RESULT=`netstat -nlp | grep $1 | awk "{print $7}" | wc -l`
}

# 初始化系统相关依赖
function is_root_user() {
    RESULT=1
    if [ $UID -ne 0 ]; then
        RESULT=0
    fi
}

# 判断当前用户是否是root用户，不是root用户就退出脚本执行
function must_root_user() {
    is_root_user
    if [ $RESULT -eq 0 ] ; then
        error "请切换到root用户"
        exit
    fi
}


# 用于读取用户输入，必须输入
function require_input() {
    if [ "$1" = "" ]; then
        error "输入内容不能为空"
        exit
    fi
    while :; do echo
      read -e -p "$1" RESULT
      if [  "$RESULT" = ""  ]; then
        error "输入内容不能为空"
      else
        break
      fi
    done
}

# 用于读取用户输入，必须输入
function input() {
    if [ "$1" = "" ]; then
        error "消息为空"
        exit
    fi
    read -e -p "$1" RESULT
}

function replace() {
    sed -i "s/$2/$3/g" $1
}

function reset_bash_completion() {
    source /etc/profile.d/bash_completion.sh
}