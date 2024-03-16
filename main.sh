#!/bin/bash

while :; do echo
    echo '请选择操作:'
    echo -e "\t1. 系统依赖环境处理"
    echo -e "\t2. 帮助"
    read -p "请输入操作编号：" option
    case "$option" in
        1)  
            clear
            bash -c "$(curl -sLk https://raw.githubusercontent.com/chaniqure/shell-tool/main/system_init.sh)"
            ;;
        2)
            clear
            bash -c "$(curl -sLk https://raw.githubusercontent.com/chaniqure/shell-tool/main/help.sh)"
            ;;
        *)
            echo -e " \033[1m \033[31m 输入参数错误，请重试 \033[0m"
        esac
done