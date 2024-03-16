#!/bin/bash

prefix=""
while :; do echo
    echo '请选择安装环境:'
    echo -e "\t1. 国内"
    echo -e "\t2. 国外"
    read -p "请输入操作编号：" env
    case "$env" in
        1)
            prefix="https://fastraw.ixnic.net/chaniqure/shell-tool/main"
            break
            ;;
        2)
            prefix="https://raw.githubusercontent.com/chaniqure/shell-tool/main"
            break
            ;;
        *)
            echo -e " \033[1m \033[31m 输入参数错误，请重试 \033[0m"
        esac
done
while :; do echo
    echo '请选择操作:'
    echo -e "\t1. 系统依赖环境处理"
    echo -e "\t2. 帮助"
    read -p "请输入操作编号：" option
    case "$option" in
        1)
            clear
            # echo -e " \033[1m \033[32m 执行地址为：$prefix/system_init.sh \033[0m"
            bash -c "$(curl -sLk $prefix/system_init.sh)"
            ;;
        2)
            clear
            # echo -e " \033[1m \033[32m 执行地址为：$prefix/help.sh \033[0m"
            bash -c "$(curl -sLk $prefix/help.sh)"
            ;;
        *)
            echo -e " \033[1m \033[31m 输入参数错误，请重试 \033[0m"
        esac
done