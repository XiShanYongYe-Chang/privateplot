#!/bin/bash

# 脚本功能：批量调用generate-contributes.sh，处理多个仓库的贡献值查询

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 显示用法信息函数
show_usage() {
    echo "用法: $0 [仓库配置文件] [时间段文件] [用户列表文件]"
    echo "示例: $0 repos.txt time_periods.txt users.txt"
    echo ""
    echo "参数说明："
    echo "  仓库配置文件   - 包含仓库信息的文件（可选，默认：repos.txt）"
    echo "  时间段文件     - 包含时间段的文件（可选，默认：time_periods.txt）"
    echo "  用户列表文件   - 包含用户列表的文件（可选，默认：users.txt）"
    echo ""
    echo "仓库配置文件格式："
    echo "每行包含：<仓库目录路径> <分支名称> [远程仓库名称]"
    echo "示例："
    echo "/path/to/repo1 main upstream"
    echo "/path/to/repo2 develop origin"
    echo "/path/to/repo3 master"
    echo ""
    echo "注意:"
    echo "- 仓库目录路径和分支名称为必需字段"
    echo "- 远程仓库名称为可选字段，默认为upstream"
    echo "- 以#开头的行为注释行，将被忽略"
    echo "- 空行将被忽略"
    echo ""
}

# 获取仓库配置文件参数
if [ -z "$1" ]; then
    REPOS_FILE="$SCRIPT_DIR/repos.txt"
    echo "使用默认仓库配置文件: $REPOS_FILE"
else
    # 如果提供的是相对路径，则相对于脚本目录
    if [[ "$1" != /* ]]; then
        REPOS_FILE="$SCRIPT_DIR/$1"
    else
        REPOS_FILE="$1"
    fi
fi

# 获取时间段文件参数
if [ -z "$2" ]; then
    TIME_PERIODS_FILE="time_periods.txt"
    echo "使用默认时间段文件: $TIME_PERIODS_FILE"
else
    TIME_PERIODS_FILE="$2"
fi

# 获取用户列表文件参数
if [ -z "$3" ]; then
    USERS_FILE="users.txt"
    echo "使用默认用户列表文件: $USERS_FILE"
else
    USERS_FILE="$3"
fi

# 显示用法信息（如果没有提供参数）
if [ $# -eq 0 ]; then
    show_usage
    echo "正在使用默认配置文件..."
    echo ""
fi

# 检查仓库配置文件是否存在
if [ ! -f "$REPOS_FILE" ]; then
    echo "错误: 仓库配置文件 $REPOS_FILE 不存在"
    echo "请创建该文件或使用-h查看帮助信息"
    exit 1
fi

# 检查generate-contributes.sh脚本是否存在
GENERATE_SCRIPT="$SCRIPT_DIR/generate-contributes.sh"
if [ ! -f "$GENERATE_SCRIPT" ]; then
    echo "错误: generate-contributes.sh 脚本不存在: $GENERATE_SCRIPT"
    exit 1
fi

# 确保generate-contributes.sh脚本有执行权限
if [ ! -x "$GENERATE_SCRIPT" ]; then
    echo "设置 generate-contributes.sh 脚本执行权限..."
    chmod +x "$GENERATE_SCRIPT"
fi

echo "开始批量处理仓库贡献值查询..."
echo "配置文件: $REPOS_FILE"
echo "时间段文件: $TIME_PERIODS_FILE"
echo "用户列表文件: $USERS_FILE"
echo ""

# 初始化计数器
TOTAL_REPOS=0
SUCCESS_COUNT=0
FAILED_COUNT=0

# 读取仓库配置文件并处理每个仓库
while IFS= read -r line || [ -n "$line" ]; do
    # 跳过空行和注释行
    if [[ -z "$line" || "$line" == \#* ]]; then
        continue
    fi
    
    # 解析仓库信息
    read -r REPO_DIR BRANCH_NAME REMOTE_NAME <<< "$line"
    
    # 检查必需字段
    if [[ -z "$REPO_DIR" || -z "$BRANCH_NAME" ]]; then
        echo "警告: 跳过无效行（缺少仓库目录或分支名称）: $line"
        continue
    fi
    
    # 如果没有指定远程仓库名称，使用默认值
    if [[ -z "$REMOTE_NAME" ]]; then
        REMOTE_NAME="upstream"
    fi
    
    TOTAL_REPOS=$((TOTAL_REPOS + 1))
    
    echo "========================================="
    echo "处理仓库 $TOTAL_REPOS: $(basename "$REPO_DIR")"
    echo "仓库路径: $REPO_DIR"
    echo "分支名称: $BRANCH_NAME"
    echo "远程仓库: $REMOTE_NAME"
    echo "========================================="
    
    # 调用generate-contributes.sh脚本
    if "$GENERATE_SCRIPT" "$REPO_DIR" "$BRANCH_NAME" "$REMOTE_NAME" "$TIME_PERIODS_FILE" "$USERS_FILE"; then
        echo "✓ 仓库 $(basename "$REPO_DIR") 处理成功"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "✗ 仓库 $(basename "$REPO_DIR") 处理失败"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
    
    echo ""
done < "$REPOS_FILE"

echo "========================================="
echo "批量处理完成"
echo "总计仓库数量: $TOTAL_REPOS"
echo "成功处理: $SUCCESS_COUNT"
echo "处理失败: $FAILED_COUNT"
echo "========================================="

# 设置退出码
if [ $FAILED_COUNT -eq 0 ]; then
    echo "所有仓库处理成功!"
    exit 0
else
    echo "有 $FAILED_COUNT 个仓库处理失败，请检查错误信息"
    exit 1
fi 