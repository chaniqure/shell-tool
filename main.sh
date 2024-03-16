#!/bin/bash

while :; do echo
    echo '请选择操作:'
    echo "\t1. 系统依赖环境处理"
    echo "\t2. 帮助"
    read -p "请输入操作编号：" option
    case "$option" in
        1)  
            clear
            bash -c "$(curl -sLk https://ddsrem.com/xiaoya/xiaoya_notify.sh)"
            ;;
        2)
            clear
            bash -c "$(curl -sLk https://ddsrem.com/xiaoya/xiaoya_notify.sh)"
            ;;
        *)
            echoError '输入参数错误，请重试'
        esac
done