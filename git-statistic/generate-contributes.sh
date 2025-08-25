#!/bin/bash

# 脚本功能：从文件中读取时间段列表，查询每个时间段内指定用户的贡献值

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载函数定义
source "$SCRIPT_DIR/by-developer.sh"

# 解析命令行参数
REPO_DIR=""
BRANCH_NAME=""
REMOTE_NAME=""
TIME_PERIODS_FILE=""
USERS_FILE=""

# 显示用法信息函数
show_usage() {
    echo "用法: $0 <仓库目录> <分支名称> [远程仓库名称] [时间段文件] [用户列表文件]"
    echo "示例: $0 /path/to/repo main upstream time_periods.txt users.txt"
    echo ""
    echo "参数说明："
    echo "  仓库目录       - Git仓库所在的目录路径"
    echo "  分支名称       - 要切换到的分支名称"
    echo "  远程仓库名称   - 远程仓库名称（可选，默认：upstream）"
    echo "  时间段文件     - 包含时间段的文件（可选，默认：time_periods.txt）"
    echo "  用户列表文件   - 包含用户列表的文件（可选，默认：users.txt）"
    echo ""
    echo "注意:"
    echo "- 前两个参数为必需参数"
    echo "- 如果不提供时间段文件和用户列表文件，将使用脚本目录下的默认文件"
    echo "- 如果提供相对路径，将相对于脚本目录解析"
    echo "- 如果提供绝对路径，将直接使用"
    echo ""
    echo "时间文件格式示例:"
    echo "2024-01-01,2024-01-31"
    echo "2024-02-01,2024-02-28"
    echo ""
}

# 检查参数数量
if [ $# -lt 2 ]; then
    echo "错误: 必须提供至少两个参数：仓库目录和分支名称"
    show_usage
    exit 1
fi

# 获取必需的参数
REPO_DIR="$1"
BRANCH_NAME="$2"

# 获取可选的远程仓库名称参数
if [ -z "$3" ]; then
    REMOTE_NAME="upstream"
    echo "使用默认远程仓库名称: $REMOTE_NAME"
else
    REMOTE_NAME="$3"
fi

# 获取可选的文件参数
if [ -z "$4" ]; then
    TIME_PERIODS_FILE="$SCRIPT_DIR/time_periods.txt"
    echo "使用默认时间段文件: $TIME_PERIODS_FILE"
else
    # 如果提供的是相对路径，则相对于脚本目录
    if [[ "$4" != /* ]]; then
        TIME_PERIODS_FILE="$SCRIPT_DIR/$4"
    else
        TIME_PERIODS_FILE="$4"
    fi
fi

if [ -z "$5" ]; then
    USERS_FILE="$SCRIPT_DIR/users.txt"
    echo "使用默认用户文件: $USERS_FILE"
else
    # 如果提供的是相对路径，则相对于脚本目录
    if [[ "$5" != /* ]]; then
        USERS_FILE="$SCRIPT_DIR/$5"
    else
        USERS_FILE="$5"
    fi
fi

# 显示用法信息（如果没有提供参数）
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

# 检查仓库目录是否存在
if [ ! -d "$REPO_DIR" ]; then
    echo "错误: 仓库目录 $REPO_DIR 不存在"
    exit 1
fi

# 检查是否为Git仓库
if [ ! -d "$REPO_DIR/.git" ]; then
    echo "错误: $REPO_DIR 不是一个Git仓库"
    exit 1
fi

# 进入仓库目录
echo "进入仓库目录: $REPO_DIR"
cd "$REPO_DIR" || {
    echo "错误: 无法进入目录 $REPO_DIR"
    exit 1
}

# 检查分支是否存在（包括远程分支）
echo "检查分支 $BRANCH_NAME 是否存在..."
if ! git show-ref --verify --quiet refs/heads/"$BRANCH_NAME" && ! git show-ref --verify --quiet refs/remotes/"$REMOTE_NAME"/"$BRANCH_NAME"; then
    echo "警告: 分支 $BRANCH_NAME 在本地和远程都不存在，将尝试从远程创建"
fi

# 拉取远程仓库的最新代码
echo "从远程仓库 $REMOTE_NAME 拉取最新代码..."
git fetch "$REMOTE_NAME" || {
    echo "错误: 无法从远程仓库 $REMOTE_NAME 拉取代码"
    exit 1
}

# 切换到指定分支
echo "切换到分支: $BRANCH_NAME"
if git show-ref --verify --quiet refs/heads/"$BRANCH_NAME"; then
    # 本地分支存在，直接切换
    git checkout "$BRANCH_NAME" || {
        echo "错误: 无法切换到分支 $BRANCH_NAME"
        exit 1
    }
elif git show-ref --verify --quiet refs/remotes/"$REMOTE_NAME"/"$BRANCH_NAME"; then
    # 远程分支存在，创建并切换到本地分支
    git checkout -b "$BRANCH_NAME" "$REMOTE_NAME/$BRANCH_NAME" || {
        echo "错误: 无法创建并切换到分支 $BRANCH_NAME"
        exit 1
    }
else
    echo "错误: 分支 $BRANCH_NAME 在远程仓库 $REMOTE_NAME 中不存在"
    exit 1
fi

# 执行rebase操作
echo "执行rebase操作..."
git rebase "$REMOTE_NAME/$BRANCH_NAME" || {
    echo "错误: rebase操作失败"
    echo "请手动解决冲突后重新运行脚本"
    exit 1
}

echo "Git操作完成，开始查询贡献值..."

# 从仓库目录路径中提取仓库名称，使用组织名+仓库名避免重名
REPO_NAME=$(basename "$REPO_DIR")
# 从路径中提取组织名，例如从 /root/go/src/github.com/karmada-io/website 提取 karmada-io
if [[ "$REPO_DIR" =~ github\.com/([^/]+)/([^/]+) ]]; then
    ORG_NAME="${BASH_REMATCH[1]}"
    REPO_BASENAME="${BASH_REMATCH[2]}"
    UNIQUE_REPO_NAME="${ORG_NAME}_${REPO_BASENAME}"
else
    # 如果不是标准的github路径，使用父目录名+仓库名
    PARENT_DIR=$(basename "$(dirname "$REPO_DIR")")
    UNIQUE_REPO_NAME="${PARENT_DIR}_${REPO_NAME}"
fi
echo "仓库标识: $UNIQUE_REPO_NAME"

# 检查时间文件是否存在
if [ ! -f "$TIME_PERIODS_FILE" ]; then
    echo "错误: 时间段文件 $TIME_PERIODS_FILE 不存在"
    exit 1
fi

# 检查用户文件是否存在
if [ ! -f "$USERS_FILE" ]; then
    echo "错误: 用户文件 $USERS_FILE 不存在"
    exit 1
fi

# 初始化用户数组
USERS=()

# 从文件读取用户或者逐行读取
while IFS= read -r AUTHOR; do
    # 跳过空行和注释行
    if [[ -n "$AUTHOR" && "$AUTHOR" != \#* ]]; then
        USERS+=("$AUTHOR")
    fi
done < "$USERS_FILE"

# 检查是否提供了用户列表
if [ ${#USERS[@]} -eq 0 ]; then
    echo "错误: 必须指定至少一个用户"
    exit 1
fi

# 检查contributions-period-total函数是否可用
if ! type contributions-period-total >/dev/null 2>&1; then
    echo "错误: contributions-period-total 函数未定义"
    echo "请确保已加载包含该函数的脚本或环境"
    exit 1
fi

# 检查contributions-period-addition函数是否可用
if ! type contributions-period-addition >/dev/null 2>&1; then
    echo "错误: contributions-period-addition 函数未定义"
    echo "请确保已加载包含该函数的脚本或环境"
    exit 1
fi

# 检查contributions-period-deletion函数是否可用
if ! type contributions-period-deletion >/dev/null 2>&1; then
    echo "错误: contributions-period-deletion 函数未定义"
    echo "请确保已加载包含该函数的脚本或环境"
    exit 1
fi

# 检查contributions-period-commits函数是否可用
if ! type contributions-period-commits >/dev/null 2>&1; then
    echo "错误: contributions-period-commits 函数未定义"
    echo "请确保已加载包含该函数的脚本或环境"
    exit 1
fi

# 检查contributions-period-large-commits-lines函数是否可用
if ! type contributions-period-large-commits-lines >/dev/null 2>&1; then
    echo "错误: contributions-period-large-commits-lines 函数未定义"
    echo "请确保已加载包含该函数的脚本或环境"
    exit 1
fi

# 检查contributions-period-large-commits-addition函数是否可用
if ! type contributions-period-large-commits-addition >/dev/null 2>&1; then
    echo "错误: contributions-period-large-commits-addition 函数未定义"
    echo "请确保已加载包含该函数的脚本或环境"
    exit 1
fi

# 检查contributions-period-large-commits-deletion函数是否可用
if ! type contributions-period-large-commits-deletion >/dev/null 2>&1; then
    echo "错误: contributions-period-large-commits-deletion 函数未定义"
    echo "请确保已加载包含该函数的脚本或环境"
    exit 1
fi

# 检查contributions-period-large-commits-count函数是否可用
if ! type contributions-period-large-commits-count >/dev/null 2>&1; then
    echo "错误: contributions-period-large-commits-count 函数未定义"
    echo "请确保已加载包含该函数的脚本或环境"
    exit 1
fi

# 输出文件按时间段分别生成（见下方循环）；文件名示例：contributions_YYYY-MM-DD_YYYY-MM-DD.csv

# 首先读取所有时间段到数组中
PERIODS=()
while IFS=',' read -r SINCE_DATE UNTIL_DATE || [ -n "$SINCE_DATE" ]; do
    # 跳过空行和注释行(以#开头的行)
    if [[ -z "$SINCE_DATE" || "$SINCE_DATE" == \#* ]]; then
        continue
    fi

    # 验证日期格式(简单验证)
    if ! [[ "$SINCE_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
       ! [[ "$UNTIL_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "警告: 跳过无效日期格式的行: $SINCE_DATE,$UNTIL_DATE"
        continue
    fi

    PERIODS+=("$SINCE_DATE,$UNTIL_DATE")
done < "$TIME_PERIODS_FILE"

# 遍历每个时间段，分别输出一个CSV文件
for period in "${PERIODS[@]}"; do
    IFS=',' read -r SINCE_DATE UNTIL_DATE <<< "$period"
    PERIOD="$SINCE_DATE - $UNTIL_DATE"

    # 设置该时间段的输出文件（保存在脚本目录）
    OUTPUT_FILE="$SCRIPT_DIR/contributions_${UNIQUE_REPO_NAME}_${BRANCH_NAME}_${SINCE_DATE}_${UNTIL_DATE}.csv"
    # echo "输出文件: $OUTPUT_FILE"
    # echo "用户名,新增代码行数,删除代码行数,贡献代码总行数,代码提交次数,超大提交代码行数(>1800行/commit),超大提交新增代码行数(>1800行/commit),超大提交删除代码行数(>1800行/commit),超大提交次数(>1800行/commit)" > "$OUTPUT_FILE"

    # 对每个用户进行处理
    for AUTHOR in "${USERS[@]}"; do
        # echo "查询用户: $AUTHOR 在时间段 $PERIOD 的贡献值"

        # 调用函数并获取新增代码行数
        addition_result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-addition)
        
        # 如果结果为空或不是数字，设置为0
        if [[ -z "$addition_result" || ! "$addition_result" =~ ^[0-9]+$ ]]; then
            addition_result="0"
        fi
        
        # 调用函数并获取删除代码行数
        deletion_result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-deletion)
        
        # 如果结果为空或不是数字，设置为0
        if [[ -z "$deletion_result" || ! "$deletion_result" =~ ^[0-9]+$ ]]; then
            deletion_result="0"
        fi

        # 调用函数并获取总贡献值
        total_result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-total)
        
        # 如果结果为空或不是数字，设置为0
        if [[ -z "$total_result" || ! "$total_result" =~ ^[0-9]+$ ]]; then
            total_result="0"
        fi
        
        # 调用函数并获取提交次数
        commits_result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-commits)
        
        # 如果结果为空或不是数字，设置为0
        if [[ -z "$commits_result" || ! "$commits_result" =~ ^[0-9]+$ ]]; then
            commits_result="0"
        fi
        
        # 调用函数并获取大提交代码行数
        large_commits_result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-large-commits-lines)
        
        # 如果结果为空或不是数字，设置为0
        if [[ -z "$large_commits_result" || ! "$large_commits_result" =~ ^[0-9]+$ ]]; then
            large_commits_result="0"
        fi
        
        # 调用函数并获取大提交新增代码行数
        large_addition_result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-large-commits-addition)
        
        # 如果结果为空或不是数字，设置为0
        if [[ -z "$large_addition_result" || ! "$large_addition_result" =~ ^[0-9]+$ ]]; then
            large_addition_result="0"
        fi
        
        # 调用函数并获取大提交删除代码行数
        large_deletion_result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-large-commits-deletion)
        
        # 如果结果为空或不是数字，设置为0
        if [[ -z "$large_deletion_result" || ! "$large_deletion_result" =~ ^[0-9]+$ ]]; then
            large_deletion_result="0"
        fi
        
        # 调用函数并获取大提交次数
        large_count_result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-large-commits-count)
        
        # 如果结果为空或不是数字，设置为0
        if [[ -z "$large_count_result" || ! "$large_count_result" =~ ^[0-9]+$ ]]; then
            large_count_result="0"
        fi
        
        # echo "新增: $addition_result, 删除: $deletion_result，总行数: $total_result, 提交次数: $commits_result, 大提交代码行数: $large_commits_result, 大提交新增: $large_addition_result, 大提交删除: $large_deletion_result, 大提交次数: $large_count_result"

        # 写入CSV文件（使用逗号分隔，如果用户名包含逗号则用双引号包围）
        if [[ "$AUTHOR" == *","* ]]; then
            echo "\"$AUTHOR\",$addition_result,$deletion_result,$total_result,$commits_result,$large_commits_result,$large_addition_result,$large_deletion_result,$large_count_result" >> "$OUTPUT_FILE"
        else
            echo "$AUTHOR,$addition_result,$deletion_result,$total_result,$commits_result,$large_commits_result,$large_addition_result,$large_deletion_result,$large_count_result" >> "$OUTPUT_FILE"
        fi
    done

done

echo "所有时间段处理完成"
echo "已为每个时间段分别生成CSV文件"
