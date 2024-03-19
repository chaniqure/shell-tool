#!/bin/sh

function isRootUser() {
    RESULT=1
    if [ $UID -ne 0 ]; then
        RESULT=0
    fi
}

# 判断当前用户是否是root用户，不是root用户就退出脚本执行
function mustRootUser() {
    isRootUser
    if [ $RESULT -eq 0 ] ; then
        echoError "please switch to root user"
        exit
    fi
}

# 打印日志，有颜色
function echoInfo(){
    echo -e " \033[1m \033[32m $1 \033[0m"
}

# 打印日志，有颜色
function echoError(){
    echo -e " \033[1m \033[31m $1 \033[0m"
}

# 用于读取用户输入
function readInput() {
    if [ "$1" = "" ]; then
        echoError "消息为空"
        exit
    fi
    while :; do echo
      read -e -p "$1" RESULT
      if [  "$RESULT" = ""  ]; then
        echo "输入内容不能为空"
      else
        break
      fi
    done
}
# 下载模板的网址的前缀，由主脚本传入
prefix=$1
echo "依赖前缀：$prefix"
readInput "请输入服务名："
# 输入服务名
# 是否需要安装成系统命令
    # 不需要的话，就输入需要生成脚本的文件路径
    # 需要的话，校验命令是否已存在
        # 生成命令提示功能
        # 打印出需要修改启动命令的脚本的路径，让用户去修改
