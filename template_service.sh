#!/bin/sh
# 项目启动端口
port=$1
# 项目根目录
home=`pwd`
# 启动服务名字
name=$2

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
    echoColor "trying to kill process by port \"$1\""
    if [ $1 -gt 0 ] ; then
        checkPortProcess $1
        if [ $RESULT -gt 0 ] ; then
            echoColor "process is running on port $1, try kill it..."
            getPortProcessId $1
            kill -9 $RESULT
        else
            echoColor "process is not running!"
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
    # _logfile "${TIME} [INFO] $1"
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
function echoColor(){
    echo -e " \033[1m \033[32m $1 \033[0m"
}

start(){
    checkPort $port
    if [ $RESULT -gt 0 ] ; then
        echoColor "${port} port is in using, please check the port"
        exit 1
    fi
    # ---------------------------- 需要添加的启动命令  -----------------------------
    # 需要后台启动
    # ++++++++++++++++ 示例：nohup ……………… >/dev/null 2>&1 & ++++++++++++++++
    # ---------------------------- 需要添加的启动命令  -----------------------------
    checkProcess $name $port
}

stop(){
    killByPort $port
}
status(){
    checkPort $port
    if [ $RESULT -gt 0 ] ; then
        getPortProcessId $port
        echoColor "${name} is in running, processId is $RESULT"
    else
        echoColor "${name} is not running"
    fi
}


restart(){
    stop
    sleep 1
    start
}

case "$1" in
    "start")
        start
        ;;
    "stop")
        stop
        ;;
    "restart")
        restart
        ;;  
    "status")
        status
        ;; 
    *)
        echoColor 'operation does not exist, available operation: start stop restart status'
esac