#!/bin/bash

# 打印日志，有颜色
function echoError(){
    echo -e " \033[1m \033[31m $1 \033[0m"
}

while :; do echo
    echo '请选择操作:'
    echo "\t1. 系统依赖环境处理"
    echo "\t2. 帮助"
    read -p "请输入操作编号：" option
    case "$option" in
        1)  
            clear
            bash -c "$(curl -sLk https://fastly.jsdelivr.net/gh/chaniqure/shell-tool@main/system_init.sh)"
            ;;
        2)
            clear
            bash -c "$(curl -sLk https://fastly.jsdelivr.net/gh/chaniqure/shell-tool@main/help.sh)"
            ;;
        *)
            echoError '输入参数错误，请重试'
        esac
done