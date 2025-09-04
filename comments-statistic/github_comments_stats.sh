#!/bin/bash

# GitHub评论统计脚本（多仓库版本）
# 用法: ./github_comments_stats.sh <repo_file> [start_date] [end_date] [user_file] [output_file]

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 默认参数（使用脚本所在目录）
DEFAULT_USER_FILE="$SCRIPT_DIR/users.txt"
DEFAULT_OUTPUT_FILE="github_comments_stats.xlsx"
DEFAULT_REPO_FILE="$SCRIPT_DIR/repos.txt"

# 函数：显示使用说明
show_usage() {
    echo "用法: $0 <start_date> <end_date> [repo_file] [user_file] [output_file]"
    echo ""
    echo "参数说明:"
    echo "  start_date  - 开始日期 (格式: YYYY-MM-DD，必填)"
    echo "  end_date    - 结束日期 (格式: YYYY-MM-DD，必填)"
    echo "  repo_file   - 仓库列表文件，每行格式: owner repo (默认: 脚本目录下的 repos.txt)"
    echo "  user_file   - 用户列表文件 (默认: 脚本目录下的 users.txt)"
    echo "  output_file - 输出Excel文件名 (默认: github_comments_stats.xlsx)"
    echo ""
    echo "仓库文件格式示例 (repos.txt):"
    echo "  microsoft vscode"
    echo "  facebook react"
    echo "  google tensorflow"
    echo ""
    echo "示例:"
    echo "  $0 2023-01-01 2023-12-31                              # 使用默认文件"
    echo "  $0 2023-01-01 2023-12-31 my_repos.txt                # 指定仓库文件"
    echo "  $0 2023-01-01 2023-12-31 repos.txt my_users.txt      # 指定仓库和用户文件"
    echo "  $0 2023-01-01 2023-12-31 repos.txt users.txt output.xlsx  # 指定所有参数"
    exit 1
}

# 检查参数数量
if [ $# -lt 2 ]; then
    echo "错误: 必须提供开始日期和结束日期"
    show_usage
fi

# 参数处理
START_DATE="$1"
END_DATE="$2"
REPO_FILE="${3:-$DEFAULT_REPO_FILE}"
USER_FILE="${4:-$DEFAULT_USER_FILE}"
OUTPUT_FILE="${5:-$DEFAULT_OUTPUT_FILE}"

# 验证日期格式
if ! [[ "$START_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "错误: 开始日期格式不正确，应为 YYYY-MM-DD"
    exit 1
fi

if ! [[ "$END_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "错误: 结束日期格式不正确，应为 YYYY-MM-DD"
    exit 1
fi

# 检查仓库文件是否存在
if [ ! -f "$REPO_FILE" ]; then
    echo "错误: 仓库文件 '$REPO_FILE' 不存在"
    exit 1
fi

# 检查用户文件是否存在
if [ ! -f "$USER_FILE" ]; then
    echo "错误: 用户文件 '$USER_FILE' 不存在"
    exit 1
fi

# 检查是否安装了必要的工具
command -v jq >/dev/null 2>&1 || { echo "错误: 需要安装 jq 工具"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "错误: 需要安装 python3"; exit 1; }

# 检查GitHub Token
if [ -z "$GITHUB_TOKEN" ]; then
    echo "警告: 未设置 GITHUB_TOKEN 环境变量"
    echo "未认证的API请求每小时限制60次，建议设置Token以提高限制到5000次/小时"
    echo ""
    echo "设置方法:"
    echo "1. 访问 https://github.com/settings/tokens"
    echo "2. 生成新的Personal Access Token (选择 'public_repo' 权限即可)"
    echo "3. 运行: export GITHUB_TOKEN=your_token_here"
    echo ""
    read -p "是否继续使用未认证的API？(y/N): " continue_without_token
    if [[ ! "$continue_without_token" =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 1
    fi
    AUTH_HEADER=""
else
    echo "✅ 检测到 GITHUB_TOKEN，将使用认证API（5000次/小时限制）"
    AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
fi

# 读取仓库列表并清理空行
mapfile -t REPOS_RAW < "$REPO_FILE"
REPOS=()
for repo_line in "${REPOS_RAW[@]}"; do
    repo_line=$(echo "$repo_line" | tr -d '\r\n' | xargs)
    if [ -n "$repo_line" ]; then
        # 检查行格式是否正确（应该包含两个参数）
        read -r owner repo <<< "$repo_line"
        if [ -n "$owner" ] && [ -n "$repo" ]; then
            REPOS+=("$owner $repo")
        else
            echo "警告: 跳过格式不正确的行: '$repo_line'"
        fi
    fi
done

echo "读取到 ${#REPOS[@]} 个仓库:"
for repo_info in "${REPOS[@]}"; do
    echo "  $repo_info"
done

# 读取用户列表并清理空行
mapfile -t USERS_RAW < "$USER_FILE"
USERS=()
for user in "${USERS_RAW[@]}"; do
    user=$(echo "$user" | tr -d '\r\n' | xargs)
    if [ -n "$user" ]; then
        USERS+=("$user")
    fi
done

echo "读取到 ${#USERS[@]} 个用户: ${USERS[*]}"

# 创建临时文件存储结果
TEMP_FILE=$(mktemp)
TEMP_SUMMARY_FILE=$(mktemp)
echo "GitHub用户名,仓库名称,评论数" > "$TEMP_FILE"
echo "GitHub用户名,总评论数" > "$TEMP_SUMMARY_FILE"

# 初始化全局用户评论计数器
declare -A global_user_comments
for user in "${USERS[@]}"; do
    global_user_comments["$user"]=0
done

# 构建时间过滤参数
START_DATE_ISO=""
END_DATE_ISO=""
if [ -n "$START_DATE" ]; then
    START_DATE_ISO="${START_DATE}T00:00:00Z"
fi
if [ -n "$END_DATE" ]; then
    END_DATE_ISO="${END_DATE}T23:59:59Z"
fi

# 函数：统计单个仓库的评论
process_repository() {
    local owner="$1"
    local repo="$2"
    local repo_name="$owner/$repo"
    
    echo ""
    echo "========================================="
    echo "开始统计 $repo_name 仓库的评论数据..."
    echo "========================================="
    
    # 初始化当前仓库的用户评论计数器
    declare -A repo_user_comments
    for user in "${USERS[@]}"; do
        repo_user_comments["$user"]=0
    done
    
    # 获取所有评论页面
    local page=1
    
    echo "正在获取评论数据..."
    
    while true; do
        echo "正在处理第 $page 页..."
        
        # 构建API URL
        local api_url="https://api.github.com/repos/$owner/$repo/issues/comments?per_page=100&page=$page"
        
        # 如果指定了开始时间，添加since参数
        if [ -n "$START_DATE_ISO" ]; then
            api_url="${api_url}&since=${START_DATE_ISO}"
        fi

        if [ -n "$END_DATE_ISO" ]; then
            api_url="${api_url}&updated_at=${END_DATE_ISO}"
        fi
        
        # 获取评论数据
        local response
        if [ -n "$AUTH_HEADER" ]; then
            response=$(curl -s -H "$AUTH_HEADER" "$api_url")
        else
            response=$(curl -s "$api_url")
        fi
        
        # 检查是否返回了有效的JSON
        if ! echo "$response" | jq . >/dev/null 2>&1; then
            echo "错误: GitHub API返回了无效响应 (仓库: $repo_name)"
            echo "响应内容: $response"
            return 1
        fi
        
        # 检查是否有数据
        local comments_count
        comments_count=$(echo "$response" | jq '. | length')
        
        if [ "$comments_count" -eq 0 ]; then
            echo "第 $page 页没有更多评论，仓库 $repo_name 统计完成"
            break
        fi
        
        echo "第 $page 页获取到 $comments_count 条评论"
        
        # 为每个用户统计评论数
        for user in "${USERS[@]}"; do
            local comments
            comments=$(echo "$response" | jq -r --arg username "$user" \
        '.[] | select(.user.login == $username) | .id')
            local page_count
            # 修复：当没有评论时，comments为空字符串，wc -l会返回1，需要特殊处理
            if [ -z "$comments" ] || [ "$comments" = "" ]; then
                page_count=0
            else
                page_count=$(echo "$comments" | wc -l)
            fi
            
            # 确保PAGE_COUNT是数字
            if ! [[ "$page_count" =~ ^[0-9]+$ ]]; then
                page_count=0
            fi
            
            # 累加到仓库总数
            local current_count=${repo_user_comments["$user"]}
            repo_user_comments["$user"]=$((current_count + page_count))
            
            if [ "$page_count" -gt 0 ]; then
                echo "  用户 $user 在第 $page 页有 $page_count 条评论"
            fi
        done
        
        # 增加页码
        page=$((page + 1))
        
        # 添加延迟以避免触发GitHub API限制
        sleep 1
    done
    
    # 将当前仓库的结果写入临时文件并累加到全局计数器
    local repo_total=0
    for user in "${USERS[@]}"; do
        local count=${repo_user_comments["$user"]}
        echo "$user,$repo_name,$count" >> "$TEMP_FILE"
        
        # 累加到全局计数器
        local global_current=${global_user_comments["$user"]}
        global_user_comments["$user"]=$((global_current + count))
        
        repo_total=$((repo_total + count))
        if [ "$count" -gt 0 ]; then
            echo "仓库 $repo_name - 用户 $user: $count 条评论"
        fi
    done
    
    echo "仓库 $repo_name 总评论数: $repo_total"
}

# 处理所有仓库
echo ""
echo "开始处理所有仓库..."
if [ -n "$START_DATE" ]; then
    echo "时间范围: $START_DATE 到 $END_DATE"
fi

for repo_info in "${REPOS[@]}"; do
    read -r owner repo <<< "$repo_info"
    process_repository "$owner" "$repo"
done

# 创建Python脚本来生成Excel文件
cat > "$TEMP_FILE.py" << 'EOF'
import sys
import csv
import pandas as pd

def csv_to_excel(detail_csv_file, summary_csv_file, excel_file):
    try:
        # 读取详细数据CSV文件
        detail_df = pd.read_csv(detail_csv_file, encoding='utf-8')
        
        # 读取汇总数据CSV文件
        summary_df = pd.read_csv(summary_csv_file, encoding='utf-8')
        
        # 写入Excel文件，包含两个工作表
        with pd.ExcelWriter(excel_file, engine='openpyxl') as writer:
            # 详细数据工作表
            detail_df.to_excel(writer, sheet_name='详细统计', index=False)
            
            # 汇总数据工作表
            summary_df.to_excel(writer, sheet_name='用户汇总', index=False)
        
        print(f"成功生成Excel文件: {excel_file}")
        print(f"  - 详细统计工作表: {len(detail_df)} 条记录")
        print(f"  - 用户汇总工作表: {len(summary_df)} 个用户")
        return True
    except ImportError:
        print("警告: 未安装pandas和openpyxl，将生成CSV文件作为替代")
        return False
    except Exception as e:
        print(f"生成Excel文件时出错: {e}")
        return False

if __name__ == "__main__":
    detail_csv_file = sys.argv[1]
    summary_csv_file = sys.argv[2]
    excel_file = sys.argv[3]
    
    if not csv_to_excel(detail_csv_file, summary_csv_file, excel_file):
        # 如果无法生成Excel，复制CSV文件
        import shutil
        detail_csv_output = excel_file.replace('.xlsx', '_detail.csv')
        summary_csv_output = excel_file.replace('.xlsx', '_summary.csv')
        shutil.copy2(detail_csv_file, detail_csv_output)
        shutil.copy2(summary_csv_file, summary_csv_output)
        print(f"已生成CSV文件:")
        print(f"  - 详细统计: {detail_csv_output}")
        print(f"  - 用户汇总: {summary_csv_output}")
EOF

# 生成汇总文件并计算总评论数
total_comments=0
for user in "${USERS[@]}"; do
    count=${global_user_comments["$user"]}
    echo "$user,$count" >> "$TEMP_SUMMARY_FILE"
    total_comments=$((total_comments + count))
done

# 运行Python脚本生成Excel文件
python3 "$TEMP_FILE.py" "$TEMP_FILE" "$TEMP_SUMMARY_FILE" "$OUTPUT_FILE"

# 显示统计结果
echo ""
echo "========================================="
echo "所有仓库统计完成！结果已保存到: $OUTPUT_FILE"
echo "========================================="
echo ""
echo "统计摘要:"
echo "----------------------------------------"
echo "处理的仓库数: ${#REPOS[@]}"
for repo_info in "${REPOS[@]}"; do
    echo "  $repo_info"
done
if [ -n "$START_DATE" ]; then
    echo "时间范围: $START_DATE 到 $END_DATE"
fi
echo "总用户数: ${#USERS[@]}"
echo "总评论数: $total_comments"
echo ""

# 显示有评论的用户（全局统计）
echo "用户评论汇总:"
for user in "${USERS[@]}"; do
    count=${global_user_comments["$user"]}
    if [ "$count" -gt 0 ]; then
        echo "  $user: $count 条评论"
    fi
done

# 清理临时文件
rm -f "$TEMP_FILE" "$TEMP_SUMMARY_FILE" "$TEMP_FILE.py"

echo ""
echo "统计完成！" 