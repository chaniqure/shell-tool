#!/bin/sh
# 下载模板的网址的前缀，由主脚本传入
env_url=$1/env/env.yml
redis_conf_url=$1/env/conf/redis.conf
mongo_conf_url=$1/env/conf/mongo.conf

home_directory=$HOME
echo "请输入根目录，默认$home_directory目录："
input "请输入根目录（默认$home_directory目录）："
# 输入需要生成开发环境的home目录，默认$HOME
