#!/bin/bash
# 项目地址：https://github.com/chaniqure/shell-tool
# 远程执行脚本命令：bash -c "$(curl -sLk  https://raw.githubusercontent.com/chaniqure/shell-tool/main/main.sh)"

function getLocation() {
    # 国内加速前缀
    innerLocation="https://fastraw.ixnic.net/chaniqure/shell-tool/main"
    # 国外GitHub官方前缀
    outerLocation="https://raw.githubusercontent.com/chaniqure/shell-tool/main"
    # 执行脚本地址变量
    location=""
    while :; do echo
        echo '请选择安装环境:'
        echo -e "\t1. GitHub CDN"
        echo -e "\t2. GitHub"
        read -p "请输入操作编号：" env
        case "$env" in
            1)
                location=$innerLocation
                break
                ;;
            2)
                location=$outerLocation
                break
                ;;
            *)
                echo -e " \033[1m \033[31m 输入参数错误，请重试 \033[0m"
            esac
    done
}

function loadRemoteFunc() {
    curl -s "$location/func.sh" -o "func.sh"
    # 检查下载是否成功
    if [ $? -eq 0 ]; then
        # 执行下载的脚本
        source "func.sh"
    else
        echo "加载公共脚本失败"
        exit 1
    fi
}


function main() {
    getLocation
    loadRemoteFunc
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
                bash -c "$(curl -sLk $location/system_init.sh)"
                ;;
            2)
                clear
                . /Users/cc/shell-tool/func.sh
                info "执行地址为：$location/env/generate_env.sh"
                # bash -c "$(curl -sLk $prefix/env/generate_env.sh)" $prefix --test=1232121
                bash /Users/cc/shell-tool/env/generate_env.sh $location
                ;;
            3)
                clear
                info "执行地址为：$location/service/generate_service.sh"
                # bash -c "$(curl -sLk $prefix/service/generate_service.sh)" $prefix --test=1232122
                bash /Users/cc/shell-tool/env/generate_env.sh $location
                ;;
            4)
                clear
                curl -o func.sh $location/func.sh
                ;;
            5)
                clear
                info "执行地址为：$location/help.sh"
                bash -c "$(curl -sLk $location/help.sh)"
                ;;
            *)
                error "输入参数错误，请重试"
            esac
    done
}
main