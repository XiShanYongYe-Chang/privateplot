#!/bin/bash

# 脚本功能：从文件中读取时间段列表，查询每个时间段内指定用户的贡献值

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
function contributions-total {
  git log --no-merges --since ${SINCE_DATE} --author "${AUTHOR}"  --numstat |\
    grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | grep -v "v1-" |\
    grep -v "reference" | grep -v "vendor" |\
    grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
    sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$1+$2}END{print total}'
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period-total {
  local result
  result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}"  --numstat |\
    grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | grep -v "v1-" |\
    grep -v "reference" | grep -v "vendor" |\
    grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
    sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$1+$2}END{print total}')
  echo "$result"
  return "$result"
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period-addition {
  local result
  result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}"  --numstat |\
    grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | grep -v "v1-" |\
    grep -v "reference" | grep -v "vendor" |\
    grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
    sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$1}END{print total}')
  echo "$result"
  return "$result"
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period-deletion {
  local result
  result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}"  --numstat |\
    grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | grep -v "v1-" |\
    grep -v "reference" | grep -v "vendor" |\
    grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
    sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$2}END{print total}')
  echo "$result"
  return "$result"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 从命令行参数获取文件名，如果未提供则使用默认文件名
if [ -z "$1" ]; then
    TIME_PERIODS_FILE="$SCRIPT_DIR/time_periods.txt"
    echo "使用默认时间段文件: $TIME_PERIODS_FILE"
else
    # 如果提供的是相对路径，则相对于脚本目录
    if [[ "$1" != /* ]]; then
        TIME_PERIODS_FILE="$SCRIPT_DIR/$1"
    else
        TIME_PERIODS_FILE="$1"
    fi
fi

if [ -z "$2" ]; then
    USERS_FILE="$SCRIPT_DIR/users.txt"
    echo "使用默认用户文件: $USERS_FILE"
else
    # 如果提供的是相对路径，则相对于脚本目录
    if [[ "$2" != /* ]]; then
        USERS_FILE="$SCRIPT_DIR/$2"
    else
        USERS_FILE="$2"
    fi
fi

# 显示用法信息（如果没有提供参数）
if [ $# -eq 0 ]; then
    echo "用法: $0 [时间段文件] [用户列表文件]"
    echo "示例: $0 time_periods.txt users.txt"
    echo ""
    echo "注意:"
    echo "- 如果不提供参数，将使用脚本目录下的默认文件"
    echo "- 如果提供相对路径，将相对于脚本目录解析"
    echo "- 如果提供绝对路径，将直接使用"
    echo ""
    echo "时间文件格式示例:"
    echo "2024-01-01,2024-01-31"
    echo "2024-02-01,2024-02-28"
    echo ""
fi

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

# 读取时间段文件并处理每个时间段
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

    echo "========================================"
    echo "处理时间段: $SINCE_DATE 至 $UNTIL_DATE"
    echo "========================================"

    # 对每个用户查询贡献值
    for AUTHOR in "${USERS[@]}"; do
        echo "查询用户: $AUTHOR 的贡献值"

        # 调用函数并获取结果
        result=$(AUTHOR="$AUTHOR" SINCE_DATE="$SINCE_DATE" UNTIL_DATE="$UNTIL_DATE" contributions-period-total)
        echo "贡献值: $result"

        echo "----------------------------------------"
    done

    echo ""
done < "$TIME_PERIODS_FILE"

echo "所有时间段处理完成"
