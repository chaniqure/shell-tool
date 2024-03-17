#!/bin/bash
# 项目地址：https://github.com/chaniqure/shell-tool

# 国内加速前缀
innerPrefix="https://fastraw.ixnic.net/chaniqure/shell-tool/main"
# 国外GitHub官方前缀
outerPrefix="https://raw.githubusercontent.com/chaniqure/shell-tool/main"

# 执行脚本地址变量
prefix=""
function getUrlPrefix() {
    while :; do echo
        echo '请选择安装环境:'
        echo -e "\t1. 国内"
        echo -e "\t2. 国外"
        read -p "请输入操作编号：" env
        case "$env" in
            1)
                prefix=$innerPrefix
                break
                ;;
            2)
                prefix=$outerPrefix
                break
                ;;
            *)
                echo -e " \033[1m \033[31m 输入参数错误，请重试 \033[0m"
            esac
    done
}

function main() {
    getUrlPrefix
    while :; do echo
        echo '请选择操作:'
        echo -e "\t1. 安装系统依赖环境"
        echo -e "\t2. 安装开发环境"
        echo -e "\t3. 创建服务"
        echo -e "\t4. 获取工具脚本"
        echo -e "\t5. 其他"
        read -p "请输入操作编号：" option
        case "$option" in
            1)
                clear
                bash -c "$(curl -sLk $prefix/system_init.sh)"
                ;;
            2)
                clear
                bash -c "$(curl -sLk $prefix/generate_env.sh)" $prefix
                ;;
            3)
                clear
                bash -c "$(curl -sLk $prefix/generate_service.sh)" $prefix
                ;;
            4)
                clear
                curl -o func1.sh $prefix/func.sh
                ;;
            5)
                clear
                echo -e " \033[1m \033[32m 执行地址为：$prefix/help.sh \033[0m"
                bash -c "$(curl -sLk $prefix/help.sh)"
                ;;
            *)
                echo -e " \033[1m \033[31m 输入参数错误，请重试 \033[0m"
            esac
    done
}
main