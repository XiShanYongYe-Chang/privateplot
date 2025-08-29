#!/bin/bash

# GitHub评论统计脚本
# 用法: ./github_comments_stats.sh <owner> <repo> [start_date] [end_date] [user_file] [output_file]

set -e

# 默认参数
DEFAULT_USER_FILE="users.txt"
DEFAULT_OUTPUT_FILE="github_comments_stats.xlsx"

# 函数：显示使用说明
show_usage() {
    echo "用法: $0 <owner> <repo> [start_date] [end_date] [user_file] [output_file]"
    echo ""
    echo "参数说明:"
    echo "  owner       - GitHub组织或用户名"
    echo "  repo        - 仓库名称"
    echo "  start_date  - 开始日期 (格式: YYYY-MM-DD，可选)"
    echo "  end_date    - 结束日期 (格式: YYYY-MM-DD，可选)"
    echo "  user_file   - 用户列表文件 (默认: users.txt)"
    echo "  output_file - 输出Excel文件名 (默认: github_comments_stats.xlsx)"
    echo ""
    echo "示例:"
    echo "  $0 microsoft vscode"
    echo "  $0 microsoft vscode 2023-01-01 2023-12-31"
    echo "  $0 microsoft vscode 2023-01-01 2023-12-31 my_users.txt my_output.xlsx"
    exit 1
}

# 检查参数
if [ $# -lt 2 ]; then
    show_usage
fi

OWNER="$1"
REPO="$2"
START_DATE="${3:-}"
END_DATE="${4:-}"
USER_FILE="${5:-$DEFAULT_USER_FILE}"
OUTPUT_FILE="${6:-$DEFAULT_OUTPUT_FILE}"

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

echo "开始统计 $OWNER/$REPO 仓库的评论数据..."
echo "用户文件: $USER_FILE"
echo "输出文件: $OUTPUT_FILE"
if [ -n "$START_DATE" ]; then
    echo "时间范围: $START_DATE 到 $END_DATE"
fi

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
echo "GitHub用户名,仓库名称,评论数" > "$TEMP_FILE"

# 初始化用户评论计数器
declare -A user_comments
for user in "${USERS[@]}"; do
    user_comments["$user"]=0
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

# 获取所有评论页面
PAGE=1
REPO_NAME="$OWNER/$REPO"

echo "正在获取评论数据..."



while true; do
    echo "正在处理第 $PAGE 页..."
    
    # 构建API URL
    API_URL="https://api.github.com/repos/$OWNER/$REPO/issues/comments?per_page=100&page=$PAGE"
    
    # 如果指定了开始时间，添加since参数
    if [ -n "$START_DATE_ISO" ]; then
        API_URL="${API_URL}&since=${START_DATE_ISO}"
    fi

    if [ -n "$END_DATE_ISO" ]; then
        API_URL="${API_URL}&updated_at=${END_DATE_ISO}"
    fi
    
    # 获取评论数据
    if [ -n "$AUTH_HEADER" ]; then
        RESPONSE=$(curl -s -H "$AUTH_HEADER" "$API_URL")
    else
        RESPONSE=$(curl -s "$API_URL")
    fi
    
    # 检查是否返回了有效的JSON
    if ! echo "$RESPONSE" | jq . >/dev/null 2>&1; then
        echo "错误: GitHub API返回了无效响应"
        echo "响应内容: $RESPONSE"
        exit 1
    fi
    
    # 检查是否有数据
    COMMENTS_COUNT=$(echo "$RESPONSE" | jq '. | length')
    
    if [ "$COMMENTS_COUNT" -eq 0 ]; then
        echo "第 $PAGE 页没有更多评论，统计完成"
        break
    fi
    
    echo "第 $PAGE 页获取到 $COMMENTS_COUNT 条评论"
    
    # 为每个用户统计评论数
    for user in "${USERS[@]}"; do
        COMMENTS=$(echo "$RESPONSE" | jq -r --arg username "$user" \
    '.[] | select(.user.login == $username) | .id')
        PAGE_COUNT=$(echo "$COMMENTS" | wc -l)
        
        # 确保PAGE_COUNT是数字
        if ! [[ "$PAGE_COUNT" =~ ^[0-9]+$ ]]; then
            PAGE_COUNT=0
        fi
        
        # 累加到总数
        current_count=${user_comments["$user"]}
        user_comments["$user"]=$((current_count + PAGE_COUNT))
        
        if [ "$PAGE_COUNT" -gt 0 ]; then
            echo "  用户 $user 在第 $PAGE 页有 $PAGE_COUNT 条评论"
        fi
    done
    
    # 增加页码
    PAGE=$((PAGE + 1))
    
    # 添加延迟以避免触发GitHub API限制
    sleep 1
done

# 生成最终结果
echo ""
echo "生成统计结果..."
total_comments=0

for user in "${USERS[@]}"; do
    count=${user_comments["$user"]}
    echo "$user,$REPO_NAME,$count" >> "$TEMP_FILE"
    total_comments=$((total_comments + count))
    echo "用户 $user: $count 条评论"
done

# 创建Python脚本来生成Excel文件
cat > "$TEMP_FILE.py" << 'EOF'
import sys
import csv
import pandas as pd

def csv_to_excel(csv_file, excel_file):
    try:
        # 读取CSV文件
        df = pd.read_csv(csv_file, encoding='utf-8')
        
        # 写入Excel文件
        with pd.ExcelWriter(excel_file, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='GitHub评论统计', index=False)
        
        print(f"成功生成Excel文件: {excel_file}")
        return True
    except ImportError:
        print("警告: 未安装pandas和openpyxl，将生成CSV文件作为替代")
        return False
    except Exception as e:
        print(f"生成Excel文件时出错: {e}")
        return False

if __name__ == "__main__":
    csv_file = sys.argv[1]
    excel_file = sys.argv[2]
    
    if not csv_to_excel(csv_file, excel_file):
        # 如果无法生成Excel，复制CSV文件
        import shutil
        csv_output = excel_file.replace('.xlsx', '.csv')
        shutil.copy2(csv_file, csv_output)
        print(f"已生成CSV文件: {csv_output}")
EOF

# 运行Python脚本生成Excel文件
python3 "$TEMP_FILE.py" "$TEMP_FILE" "$OUTPUT_FILE"

# 显示统计结果
echo ""
echo "========================================="
echo "统计完成！结果已保存到: $OUTPUT_FILE"
echo "========================================="
echo ""
echo "统计摘要:"
echo "----------------------------------------"
echo "仓库: $REPO_NAME"
if [ -n "$START_DATE" ]; then
    echo "时间范围: $START_DATE 到 $END_DATE"
fi
echo "总用户数: ${#USERS[@]}"
echo "总评论数: $total_comments"
echo ""

# 显示有评论的用户
echo "有评论的用户:"
for user in "${USERS[@]}"; do
    count=${user_comments["$user"]}
    if [ "$count" -gt 0 ]; then
        echo "  $user: $count 条评论"
    fi
done

# 清理临时文件
rm -f "$TEMP_FILE" "$TEMP_FILE.py"

echo ""
echo "统计完成！" 