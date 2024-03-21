#!/bin/sh

service_template_url=$1/service/template/service_template.sh
service_dir=$HOME
function create_service_completion() {
    # 工具名称作为参数传入
    if [ ! -d "/etc/bash_completion.d" ]; then
        info "/etc/bash_completion.d 文件夹不存在，开始安装 bash-completion 工具"
        apt-get update && apt-get install bash-completion && mkdir -p /etc/bash_completion.d
    fi
    name=$1
    # 完成脚本的内容
    content=$(cat <<EOF
_${name}_completion() {
    local cur=\${COMP_WORDS[COMP_CWORD]}
    local commands="start stop restart status"

    if [[ \${COMP_CWORD} == 1 ]]; then
        COMPREPLY=( \$(compgen -W "\${commands}" -- \${cur}) )
        return 0
    fi
}
complete -F _${name}_completion ${name}
EOF
    )
    # 动态生成脚本文件名
    script_name="${name}-completion.bash"
    # 将完成脚本内容写入文件
    echo "$content" > "/etc/bash_completion.d/$script_name"
    source "/etc/bash_completion.d/$script_name"
    info "创建 '$script_name' tab提示文件成功."
    warn "由于某些原因，需手动执行命令添加提示：source /etc/bash_completion.d/$script_name"
}



function get_template() {
    curl -o $service_dir/template.sh $service_template_url
    clear
    input "下载脚本模板完成，路径：$service_dir/template.sh，修改里面的服务名和端口以及启动命令，按任意键退出"
}

function init_service() {
    must_root_user
    require_input "请输入服务名："
    if [ -f $RESULT ]; then
        while true; do
            input "检测到 $RESULT 已存在，请换一个名字："
            if [ ! -f $RESULT ]; then
                break
            fi
        done
    fi
    service_name=$RESULT
    require_input "请输入服务启动端口："
    service_port=$RESULT
    curl -o /usr/local/bin/$service_name $service_template_url
    replace /usr/local/bin/$service_name "\$SERVICE_NAME" $service_name
    replace /usr/local/bin/$service_name "\$PORT" $service_port
    chmod a+x /usr/local/bin/$service_name
    create_service_completion $service_name
    info "创建服务完成，启动文件路径：/usr/local/bin/$service_name，修改里面的服务名和端口以及启动命令"
    input "按任意键退出"
}
function remove_service() {
    must_root_user
    require_input "请输入服务名："
    if [ ! -f "/usr/local/bin/$RESULT" ]; then
        while true; do
            input "检测到 /usr/local/bin/$RESULT 不存在，请确定服务名字："
            if [ -f $RESULT ]; then
                break
            fi
        done
    fi
    service_name=$RESULT
    rm -rf /usr/local/bin/$service_name
    rm -rf /etc/bash_completion.d/$service_name-completion.bash
    info "创建服务完成，启动文件路径：/usr/local/bin/$service_name，修改里面的服务名和端口以及启动命令"
    input "按任意键退出"
}
# 下载模板的网址的前缀，由主脚本传入
# 输入服务名
# 是否需要安装成系统命令
    # 不需要的话，就输入需要生成脚本的文件路径
    # 需要的话，校验命令是否已存在
        # 生成命令提示功能
        # 打印出需要修改启动命令的脚本的路径，让用户去修改
function generate_service() {
   while :; do echo
        printf "
#######################################################################
                            生成单项目启动脚本
#######################################################################
"
        echo -e '请选择操作'
        echo -e "\t1. 下载单项目启动脚本"
        echo -e "\t2. 创建单项目控制服务"
        echo -e "\t3. 移除单项目控制服务"
        read -p "请输入操作编号：" option
        case "$option" in
        1)
            get_template
            ;;
        2)
            clear
            init_service
            ;;
        3)
            clear
            remove_service
            ;;
        *)
            error '输入参数错误，请重试'
        esac

    done
}

generate_service