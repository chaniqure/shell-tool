#!/bin/sh
# 用于部署单个项目，里面包含单个项目的启动、关闭、以及重启等操作
# 项目启动端口，需要替换，用于关闭服务
# ---------------------------- 需要修改的地方  -----------------------------
port=$PORT
# 启动服务名字，需要替换成实际的名字，用于日志打印
name=$SERVICE_NAME
# ---------------------------- 需要修改的地方  -----------------------------
# 校验端口是否占用
function check_port() {
    check_port_process $1
    if [ $RESULT -gt 0 ] ; then
        RESULT=1
    else
        RESULT=0
    fi
}

# 通过端口杀死进程
function kill_by_port() {
    info "trying to kill process by port \"$1\""
    if [ $1 -gt 0 ] ; then
        check_port_process $1
        if [ $RESULT -gt 0 ] ; then
            info "process is running on port $1, try kill it..."
            get_port_process_id $1
            kill -9 $RESULT
        else
            info "process is not running!"
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

# 记录info日志文件
function info() {
    TIME=`date '+%Y-%m-%d %H:%M:%S'`
    echo -e "\033[34m ${TIME}\033[1m \033[32m [INFO] \033[0m $1"
    # _logfile "${TIME} [INFO] $1"
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

start(){
    check_port $port
    if [ $RESULT -gt 0 ] ; then
        info "${port} port is in using, please check the port"
        exit 1
    fi
    # ---------------------------- 需要添加的启动命令  -----------------------------
    # 需要后台启动
    # ++++++++++++++++ 示例：nohup ……………… >/dev/null 2>&1 & ++++++++++++++++
    # ---------------------------- 需要添加的启动命令  -----------------------------
    check_process $name $port
}

stop(){
    kill_by_port $port
}
status(){
    check_port $port
    if [ $RESULT -gt 0 ] ; then
        get_port_process_id $port
        info "${name} is in running, processId is $RESULT"
    else
        info "${name} is not running"
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
        info 'operation does not exist, available operation: start stop restart status'
esac