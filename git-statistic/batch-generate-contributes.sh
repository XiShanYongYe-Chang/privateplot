#!/bin/bash

# 脚本功能：批量调用generate-contributes.sh，处理多个仓库的贡献值查询

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 显示用法信息函数
show_usage() {
    echo "用法: $0 <是否包含vendor> [仓库配置文件] [时间段文件] [用户列表文件]"
    echo "示例: $0 true repos.txt time_periods.txt users.txt"
    echo ""
    echo "参数说明："
    echo "  是否包含vendor - 是否统计vendor文件贡献（必填）"
    echo "                  true：统计vendor文件，调用with-vendor函数"
    echo "                  false：不统计vendor文件，调用普通函数"
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

# 检查是否提供了必填的vendor参数
if [ $# -eq 0 ]; then
    echo "错误: 必须提供vendor参数"
    show_usage
    exit 1
fi

# 获取第1个参数：是否包含vendor（必填）
INCLUDE_VENDOR="$1"
if [[ "$INCLUDE_VENDOR" != "true" && "$INCLUDE_VENDOR" != "false" ]]; then
    echo "错误: vendor参数只能为true或false"
    show_usage
    exit 1
fi

echo "是否包含vendor文件: $INCLUDE_VENDOR"

# 获取仓库配置文件参数
if [ -z "$2" ]; then
    REPOS_FILE="$SCRIPT_DIR/repos.txt"
    echo "使用默认仓库配置文件: $REPOS_FILE"
else
    # 如果提供的是相对路径，则相对于脚本目录
    if [[ "$2" != /* ]]; then
        REPOS_FILE="$SCRIPT_DIR/$2"
    else
        REPOS_FILE="$2"
    fi
fi

# 获取时间段文件参数
if [ -z "$3" ]; then
    TIME_PERIODS_FILE="time_periods.txt"
    echo "使用默认时间段文件: $TIME_PERIODS_FILE"
else
    TIME_PERIODS_FILE="$3"
fi

# 获取用户列表文件参数
if [ -z "$4" ]; then
    USERS_FILE="users.txt"
    echo "使用默认用户列表文件: $USERS_FILE"
else
    USERS_FILE="$4"
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

# 存储所有生成的CSV文件
ALL_CSV_FILES=()

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
    if "$GENERATE_SCRIPT" "$REPO_DIR" "$BRANCH_NAME" "$INCLUDE_VENDOR" "$REMOTE_NAME" "$TIME_PERIODS_FILE" "$USERS_FILE"; then
        echo "✓ 仓库 $(basename "$REPO_DIR") 处理成功"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        
        # 记录该仓库生成的CSV文件
        # 使用更完整的路径信息来避免重名
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
        
        # 读取时间段文件，记录生成的CSV文件
        while IFS=',' read -r SINCE_DATE UNTIL_DATE || [ -n "$SINCE_DATE" ]; do
            # 跳过空行和注释行
            if [[ -z "$SINCE_DATE" || "$SINCE_DATE" == \#* ]]; then
                continue
            fi
            
            # 验证日期格式
            if [[ "$SINCE_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ "$UNTIL_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                CSV_FILE="$SCRIPT_DIR/contributions_${UNIQUE_REPO_NAME}_${BRANCH_NAME}_${SINCE_DATE}_${UNTIL_DATE}.csv"
                if [ -f "$CSV_FILE" ]; then
                    ALL_CSV_FILES+=("$CSV_FILE")
                fi
            fi
        done < "$SCRIPT_DIR/$TIME_PERIODS_FILE"
        
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

# 如果有成功处理的仓库，开始合并处理
if [ $SUCCESS_COUNT -gt 0 ]; then
    echo ""
    echo "开始合并同一时间段的CSV文件..."
    
    # 检查是否安装了csvkit或其他CSV处理工具
    if ! command -v csvstack >/dev/null 2>&1; then
        echo "警告: 未找到csvstack命令，尝试安装csvkit..."
        pip install csvkit 2>/dev/null || {
            echo "警告: 无法安装csvkit，将使用简单的文本合并方式"
            USE_SIMPLE_MERGE=true
        }
    fi
    
    # 读取时间段文件并为每个时间段合并文件
    while IFS=',' read -r SINCE_DATE UNTIL_DATE || [ -n "$SINCE_DATE" ]; do
        # 跳过空行和注释行
        if [[ -z "$SINCE_DATE" || "$SINCE_DATE" == \#* ]]; then
            continue
        fi
        
        # 验证日期格式
        if ! [[ "$SINCE_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || ! [[ "$UNTIL_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            continue
        fi
        
        echo "处理时间段: $SINCE_DATE 到 $UNTIL_DATE"
        
        # 查找该时间段的所有CSV文件
        PERIOD_FILES=()
        for csv_file in "${ALL_CSV_FILES[@]}"; do
            if [[ "$csv_file" == *"_${SINCE_DATE}_${UNTIL_DATE}.csv" ]]; then
                if [ -f "$csv_file" ]; then
                    PERIOD_FILES+=("$csv_file")
                fi
            fi
        done
        
        if [ ${#PERIOD_FILES[@]} -eq 0 ]; then
            echo "警告: 未找到时间段 $SINCE_DATE 到 $UNTIL_DATE 的CSV文件"
            continue
        fi
        
        echo "找到 ${#PERIOD_FILES[@]} 个文件需要合并"
        
        # 设置合并后的临时文件名
        MERGED_CSV="$SCRIPT_DIR/merged_contributions_${SINCE_DATE}_${UNTIL_DATE}.csv"
        FINAL_EXCEL="$SCRIPT_DIR/contributions_${SINCE_DATE}_${UNTIL_DATE}.xlsx"
        
        # 创建合并后的CSV文件头
        echo "用户名,仓库,分支,新增代码行数,删除代码行数,贡献代码总行数,代码提交次数,超大提交代码行数(>1800行/commit),超大提交新增代码行数(>1800行/commit),超大提交删除代码行数(>1800行/commit),超大提交次数(>1800行/commit)" > "$MERGED_CSV"
        
                 # 合并所有文件的数据（跳过标题行）
         for csv_file in "${PERIOD_FILES[@]}"; do
             # 从文件名提取仓库名和分支名
             filename=$(basename "$csv_file")
             # 移除前缀和后缀，提取仓库名和分支名
             temp=${filename#contributions_}
             temp=${temp%_${SINCE_DATE}_${UNTIL_DATE}.csv}
             
             # 分割仓库名和分支名（现在仓库名可能包含组织名，格式为 org_repo_branch）
             # 使用更智能的方式分割：最后一个下划线之前的是仓库名，之后的是分支名
             if [[ "$temp" =~ ^(.+)_([^_]+)$ ]]; then
                 repo_name="${BASH_REMATCH[1]}"
                 branch_name="${BASH_REMATCH[2]}"
             else
                 repo_name="$temp"
                 branch_name="unknown"
             fi
            
             {
                 tail -n +2 "$csv_file" | while IFS=',' read -r user add del total commits large_lines large_add large_del large_count; do
                     # 处理可能包含引号的用户名
                     user=$(echo "$user" | sed 's/^"//;s/"$//')
                     echo "\"$user\",\"$repo_name\",\"$branch_name\",$add,$del,$total,$commits,$large_lines,$large_add,$large_del,$large_count"
                 done
             } >> "$MERGED_CSV"
        done
        
        # 对合并文件按用户名排序
        SORTED_DETAIL_CSV="$SCRIPT_DIR/sorted_detail_contributions_${SINCE_DATE}_${UNTIL_DATE}.csv"
        
        # 首先提取表头
        head -n 1 "$MERGED_CSV" > "$SORTED_DETAIL_CSV"
        
        # 然后对数据按用户名排序
        tail -n +2 "$MERGED_CSV" | sort -t',' -k1,1 >> "$SORTED_DETAIL_CSV"
        
        # 创建汇总数据（按用户聚合）
        SUMMARY_CSV="$SCRIPT_DIR/summary_contributions_${SINCE_DATE}_${UNTIL_DATE}.csv"
        echo "用户名,新增代码行数,删除代码行数,贡献代码总行数,代码提交次数,超大提交代码行数(>1800行/commit),超大提交新增代码行数(>1800行/commit),超大提交删除代码行数(>1800行/commit),超大提交次数(>1800行/commit)" > "$SUMMARY_CSV"
        
        # 使用awk来汇总数据
        tail -n +2 "$MERGED_CSV" | awk -F',' '
        {
            user = $1
            gsub(/^"|"$/, "", user)  # 移除引号
            add[user] += $4
            del[user] += $5
            total[user] += $6
            commits[user] += $7
            large_lines[user] += $8
            large_add[user] += $9
            large_del[user] += $10
            large_count[user] += $11
        }
        END {
            # 将用户名存储到数组中以便排序
            n = 0
            for (u in add) {
                users[n++] = u
            }
            # 简单的冒泡排序按用户名首字母排序
            for (i = 0; i < n-1; i++) {
                for (j = 0; j < n-1-i; j++) {
                    if (tolower(users[j]) > tolower(users[j+1])) {
                        temp = users[j]
                        users[j] = users[j+1]
                        users[j+1] = temp
                    }
                }
            }
            # 输出排序后的结果
            for (i = 0; i < n; i++) {
                u = users[i]
                printf "\"%s\",%d,%d,%d,%d,%d,%d,%d,%d\n", u, add[u], del[u], total[u], commits[u], large_lines[u], large_add[u], large_del[u], large_count[u]
            }
        }' >> "$SUMMARY_CSV"
        
        # 尝试转换为Excel格式
        CONVERTER_SCRIPT="$SCRIPT_DIR/csv_to_excel.py"
        if [ -f "$CONVERTER_SCRIPT" ] && command -v python3 >/dev/null 2>&1; then
            echo "正在转换为Excel格式（包含详细数据和汇总数据）..."
            python3 "$CONVERTER_SCRIPT" "$SORTED_DETAIL_CSV" "$SUMMARY_CSV" "$FINAL_EXCEL" && {
                # 删除临时CSV文件
                rm -f "$MERGED_CSV" "$SORTED_DETAIL_CSV" "$SUMMARY_CSV"
            } || {
                echo "警告: Excel转换失败，保留CSV格式文件"
                mv "$SORTED_DETAIL_CSV" "${SORTED_DETAIL_CSV%.csv}_final.csv"
                mv "$SUMMARY_CSV" "${SUMMARY_CSV%.csv}_final.csv"
                rm -f "$MERGED_CSV"
            }
        elif command -v ssconvert >/dev/null 2>&1; then
            echo "使用ssconvert转换为Excel格式（仅汇总数据）..."
            ssconvert "$SUMMARY_CSV" "$FINAL_EXCEL" 2>/dev/null && {
                echo "✓ 成功生成Excel文件: $FINAL_EXCEL"
                echo "注意: 由于使用ssconvert，仅包含汇总数据，详细数据已保存为CSV文件"
                # 保留详细数据CSV文件，删除其他临时文件
                mv "$SORTED_DETAIL_CSV" "${SORTED_DETAIL_CSV%.csv}_detail.csv"
                rm -f "$MERGED_CSV" "$SUMMARY_CSV"
            } || {
                echo "警告: Excel转换失败，保留CSV格式文件"
                mv "$SORTED_DETAIL_CSV" "${SORTED_DETAIL_CSV%.csv}_final.csv"
                mv "$SUMMARY_CSV" "${SUMMARY_CSV%.csv}_final.csv"
                rm -f "$MERGED_CSV"
            }
        else
            echo "警告: 未找到Excel转换工具，保留CSV格式文件"
            mv "$SORTED_DETAIL_CSV" "${SORTED_DETAIL_CSV%.csv}_detail_final.csv"
            mv "$SUMMARY_CSV" "${SUMMARY_CSV%.csv}_summary_final.csv"
            rm -f "$MERGED_CSV"
        fi
        
        echo "完成时间段 $SINCE_DATE 到 $UNTIL_DATE 的文件合并"
        echo ""
        
    done < "$SCRIPT_DIR/$TIME_PERIODS_FILE"
    
    # 删除所有中间生成的CSV文件
    echo "清理中间文件..."
    for csv_file in "${ALL_CSV_FILES[@]}"; do
        if [ -f "$csv_file" ]; then
            rm -f "$csv_file"
            # echo "删除: $csv_file"
        fi
    done
    
    echo "========================================="
    echo "文件合并处理完成"
    echo "每个时间段的最终文件已生成并按用户首字母排序"
    echo "Excel文件包含两个工作表："
    echo "  1. 详细贡献数据 - 每个用户在每个仓库中的具体贡献值"
    echo "  2. 汇总贡献统计 - 每个用户在该时间段的总贡献值"
    echo "所有中间文件已删除"
    echo "========================================="
fi

# 设置退出码
if [ $FAILED_COUNT -eq 0 ]; then
    echo "所有仓库处理成功!"
    exit 0
else
    echo "有 $FAILED_COUNT 个仓库处理失败，请检查错误信息"
    exit 1
fi 