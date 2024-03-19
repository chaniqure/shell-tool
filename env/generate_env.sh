#!/bin/sh
# 下载模板的网址的前缀，由主脚本传入
env_url=$1/env/template/env.yml
redis_conf_url=$1/env/template/redis.conf
mongo_conf_url=$1/env/template/mongo.conf
printf "
#######################################################################
                           开始初始化开发环境
#######################################################################
"
env_dir=$HOME/env
# env_dir="/Users/cc/Downloads/env"
function init_env_dir() {
    input "请输入根目录（默认$env_dir目录）："
    # 输入需要生成开发环境的home目录，默认$HOME
    if [ ! -z "$RESULT" ]; then
        env_dir=$RESULT/env
    fi
}

function init_db_user_config() {
    mysql_root_pass="123456"
    input "请输入mysql的root密码（默认：123456）："
    if [ ! -z "$RESULT" ]; then
        mysql_root_pass=$RESULT
    fi
    input "请输入redis密码（默认：123456）："
    redis_pass="123456"
    if [ ! -z "$RESULT" ]; then
        redis_pass=$RESULT
    fi
    input "请输入mongo用户名（默认：test）："
    mongo_user="test"
    if [ ! -z "$RESULT" ]; then
        mongo_user=$RESULT
    fi
    input "请输入mongo用户密码（默认：123456）："
    mongo_pass="123456"
    if [ ! -z "$RESULT" ]; then
        mongo_pass=$RESULT
    fi
}

function download_template() {
    if [ -d $env_dir ]; then
        while true; do
            input "检测到 $env_dir 已存在，是否删除？(y/n)："
            if [ "$RESULT" == "n" ]; then
                exit # 完全退出脚本
            elif [ "$RESULT" == "y" ]; then
                rm -rf $env_dir
                break
            else
                error "输入的选项错误！"
            fi
        done
    fi
    mkdir -p $env_dir/docker/conf
    mkdir -p $env_dir/docker/data
    curl -o $env_dir/env.yml $env_url
    replace $env_dir/env.yml "\$MYSQL_ROOT_PASS" $mysql_root_pass
    replace $env_dir/env.yml "\$MONGO_USER" $mongo_user
    replace $env_dir/env.yml "\$MONGO_PASS" $mongo_pass
#     sed -i "s/$MONGO_USER/$mongo_user/g" $env_dir/env.yml
    curl -o $env_dir/docker/conf/redis.conf $redis_conf_url
    replace $env_dir/docker/conf/redis.conf "\$REDIS_PASS" $redis_pass
    curl -o $env_dir/docker/conf/mongo.conf $mongo_conf_url
}

function db_tips() {
    info "
MySQL创建远程登录账号：
# mysql8以下
GRANT ALL PRIVILEGES ON *.* TO 'myuser'@'192.168.1.3'IDENTIFIED BY 'mypassword' WITH GRANT OPTION
GRANT ALL PRIVILEGES ON *.* TO 'myuser'@'%' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;

# mysql8
create user 'myuser'@'%' identified by 'mypassword';
grant all privileges on *.* to 'cc'@'%' with grant option;
# 授权语句，特别注意有分号
flush privileges;
    "
}

function generate_env() {
    init_env_dir
    init_db_user_config
    download_template
    db_tips
    input "按任意键返回"
}
generate_env