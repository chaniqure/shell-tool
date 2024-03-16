#!/bin/bash

# 工具名称作为参数传入
name=$1

# 完成脚本的内容
content=$(cat <<EOF
_tool_completion() {
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
script_name="${name}-completion.sh"

# 将完成脚本内容写入文件
echo "$content" > "$script_name"

echo "Completion script '$script_name' has been created."