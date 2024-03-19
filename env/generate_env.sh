#!/bin/sh
# 下载模板的网址的前缀，由主脚本传入
prefix=$1
info "获取到的前缀地址为：$prefix"
readInput "根目录："
# 输入需要生成开发环境的home目录，默认$HOME
