#!/bin/bash

# 脚本功能：从文件中读取时间段列表，查询每个时间段内指定用户的贡献值

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载函数定义
source "$SCRIPT_DIR/by-developer.sh"

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

# 设置输出文件（保存到当前工作目录）
OUTPUT_FILE="contributions_report.csv"
echo "输出文件: $OUTPUT_FILE"

# 创建CSV文件并写入表头
echo "用户名,时间段,新增代码行数,删除代码行数,贡献代码总行数,代码提交次数,超大提交代码行数(>1800行/commit),超大提交新增代码行数(>1800行/commit),超大提交删除代码行数(>1800行/commit),超大提交次数(>1800行/commit)" > "$OUTPUT_FILE"

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

# 对每个用户进行处理
for AUTHOR in "${USERS[@]}"; do
    echo "========================================"
    echo "处理用户: $AUTHOR"
    echo "========================================"
    
    # 初始化该用户的总计数据
    user_total_addition=0
    user_total_deletion=0
    user_total_lines=0
    user_total_commits=0
    user_total_large_commits=0
    user_total_large_addition=0
    user_total_large_deletion=0
    user_total_large_count=0
    
    # 对该用户的所有时间段进行计算
    for period in "${PERIODS[@]}"; do
        IFS=',' read -r SINCE_DATE UNTIL_DATE <<< "$period"
        PERIOD="$SINCE_DATE - $UNTIL_DATE"
        
        echo "查询用户: $AUTHOR 在时间段 $PERIOD 的贡献值"

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
        
        echo "新增: $addition_result, 删除: $deletion_result，总行数: $total_result, 提交次数: $commits_result, 大提交代码行数: $large_commits_result, 大提交新增: $large_addition_result, 大提交删除: $large_deletion_result, 大提交次数: $large_count_result"

        # 累加到用户总计
        user_total_addition=$((user_total_addition + addition_result))
        user_total_deletion=$((user_total_deletion + deletion_result))
        user_total_lines=$((user_total_lines + total_result))
        user_total_commits=$((user_total_commits + commits_result))
        user_total_large_commits=$((user_total_large_commits + large_commits_result))
        user_total_large_addition=$((user_total_large_addition + large_addition_result))
        user_total_large_deletion=$((user_total_large_deletion + large_deletion_result))
        user_total_large_count=$((user_total_large_count + large_count_result))

        # 写入CSV文件（使用逗号分隔，如果用户名包含逗号则用双引号包围）
        if [[ "$AUTHOR" == *","* ]]; then
            echo "\"$AUTHOR\",\"$PERIOD\",$addition_result,$deletion_result,$total_result,$commits_result,$large_commits_result,$large_addition_result,$large_deletion_result,$large_count_result" >> "$OUTPUT_FILE"
        else
            echo "$AUTHOR,$PERIOD,$addition_result,$deletion_result,$total_result,$commits_result,$large_commits_result,$large_addition_result,$large_deletion_result,$large_count_result" >> "$OUTPUT_FILE"
        fi
    done
    
    # 输出该用户的总计数据
    echo "----------------------------------------"
    echo "用户 $AUTHOR 总计:"
    echo "总新增: $user_total_addition, 总删除: $user_total_deletion, 总行数: $user_total_lines, 总提交次数: $user_total_commits, 总大提交代码行数: $user_total_large_commits, 总大提交新增: $user_total_large_addition, 总大提交删除: $user_total_large_deletion, 总大提交次数: $user_total_large_count"
    echo "----------------------------------------"
    
    # 写入用户总计行到CSV文件
    if [[ "$AUTHOR" == *","* ]]; then
        echo "\"$AUTHOR\",\"所有时间段总计\",$user_total_addition,$user_total_deletion,$user_total_lines,$user_total_commits,$user_total_large_commits,$user_total_large_addition,$user_total_large_deletion,$user_total_large_count" >> "$OUTPUT_FILE"
    else
        echo "$AUTHOR,所有时间段总计,$user_total_addition,$user_total_deletion,$user_total_lines,$user_total_commits,$user_total_large_commits,$user_total_large_addition,$user_total_large_deletion,$user_total_large_count" >> "$OUTPUT_FILE"
    fi
    
    echo ""
done

echo "所有时间段处理完成"
echo "结果已保存到: $OUTPUT_FILE"
echo "您可以用Excel打开此CSV文件查看详细结果"
