# GitHub 多仓库评论统计脚本使用指南

这个脚本可以统计多个 GitHub 仓库中指定用户在特定时间范围内的评论数量，并生成详细的 Excel 报告。

## 📋 目录结构

```
comments-statistic/
├── github_comments_stats.sh    # 主脚本文件
├── repos.txt                   # 仓库列表配置文件
├── users.txt                   # 用户列表配置文件
└── README.md                   # 使用指南
```

## ✨ 功能特性

- 🏢 **多仓库支持**：同时统计多个 GitHub 仓库的评论数据
- 📅 **时间范围过滤**：支持指定开始和结束日期进行精确统计
- 📊 **双重报告**：生成详细统计和用户汇总两个工作表的 Excel 文件
- 🔧 **灵活配置**：支持自定义仓库列表和用户列表文件
- 🚀 **API 优化**：支持 GitHub Token 认证，提高请求限制
- 📈 **进度显示**：实时显示统计进度和结果摘要
- 🛡️ **错误处理**：完善的错误检查和用户友好的错误提示

## 🚀 快速开始

### 1. 环境准备

确保系统已安装必需工具：

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install jq curl python3 python3-pip

# CentOS/RHEL
sudo yum install jq curl python3 python3-pip

# macOS
brew install jq curl python3
```

安装 Python 依赖（推荐）：
```bash
pip3 install pandas openpyxl
```

### 2. 配置 GitHub Token（推荐）

```bash
# 1. 访问 https://github.com/settings/tokens
# 2. 生成新的 Personal Access Token（选择 'public_repo' 权限）
# 3. 设置环境变量
export GITHUB_TOKEN=your_token_here

# 或者添加到 ~/.bashrc 中永久生效
echo "export GITHUB_TOKEN=your_token_here" >> ~/.bashrc
source ~/.bashrc
```

### 3. 配置文件设置

#### 仓库列表文件 (repos.txt)
每行包含一个仓库，格式为 `owner repository`：
```
karmada-io karmada
karmada-io website
kubernetes kubernetes
microsoft vscode
facebook react
```

#### 用户列表文件 (users.txt)
每行包含一个 GitHub 用户名：
```
XiShanYongYe-Chang
liaolecheng
RainbowMango
zhzhuang-zju
```

### 4. 运行脚本

```bash
# 基本用法（使用默认配置文件）
./github_comments_stats.sh 2023-01-01 2023-12-31

# 指定自定义仓库文件
./github_comments_stats.sh 2023-01-01 2023-12-31 my_repos.txt

# 完整参数示例
./github_comments_stats.sh 2023-01-01 2023-12-31 repos.txt users.txt output.xlsx
```

## 📖 详细使用说明

### 命令语法

```bash
./github_comments_stats.sh <start_date> <end_date> [repo_file] [user_file] [output_file]
```

### 参数详解

| 参数 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `start_date` | 必填 | 统计开始日期，格式：YYYY-MM-DD | `2023-01-01` |
| `end_date` | 必填 | 统计结束日期，格式：YYYY-MM-DD | `2023-12-31` |
| `repo_file` | 可选 | 仓库列表文件路径（默认：脚本目录下的 repos.txt） | `my_repos.txt` |
| `user_file` | 可选 | 用户列表文件路径（默认：脚本目录下的 users.txt） | `my_users.txt` |
| `output_file` | 可选 | 输出文件名（默认：github_comments_stats.xlsx） | `report_2023.xlsx` |

### 使用场景示例

#### 场景1：季度评论统计
```bash
# 统计2023年第一季度的评论数据
./github_comments_stats.sh 2023-01-01 2023-03-31
```

#### 场景2：特定项目评估
```bash
# 创建特定项目的仓库列表
echo "kubernetes kubernetes" > k8s_repos.txt
echo "kubernetes client-go" >> k8s_repos.txt

# 统计特定项目
./github_comments_stats.sh 2023-01-01 2023-12-31 k8s_repos.txt
```

#### 场景3：团队成员活跃度分析
```bash
# 创建团队成员列表
cat > team_members.txt << EOF
alice
bob
charlie
diana
EOF

# 生成团队活跃度报告
./github_comments_stats.sh 2023-01-01 2023-12-31 repos.txt team_members.txt team_activity_2023.xlsx
```

## 📊 输出说明

脚本会生成包含两个工作表的 Excel 文件：

### 工作表1：详细统计
包含每个用户在每个仓库中的评论数：

| GitHub用户名 | 仓库名称 | 评论数 |
|-------------|----------|--------|
| XiShanYongYe-Chang | karmada-io/karmada | 25 |
| liaolecheng | karmada-io/karmada | 18 |
| RainbowMango | karmada-io/website | 12 |
| ... | ... | ... |

### 工作表2：用户汇总
显示每个用户在所有仓库中的总评论数：

| GitHub用户名 | 总评论数 |
|-------------|----------|
| XiShanYongYe-Chang | 45 |
| liaolecheng | 32 |
| RainbowMango | 28 |
| zhzhuang-zju | 15 |

## 🔧 高级配置

### 自定义输出格式

如果未安装 pandas 和 openpyxl，脚本会自动生成 CSV 文件：
- `output_detail.csv` - 详细统计数据
- `output_summary.csv` - 用户汇总数据

### API 限制管理

| 认证状态 | 请求限制 | 建议使用场景 |
|----------|----------|-------------|
| 未认证 | 60次/小时 | 小规模测试（<5个仓库，<10个用户） |
| 已认证 | 5000次/小时 | 生产环境使用 |

### 性能优化建议

1. **批量处理**：对于大量仓库，建议分批处理
2. **时间分段**：长时间范围可以分段统计后合并
3. **缓存策略**：相同时间范围的数据可以复用

## 🐛 故障排除

### 常见错误及解决方案

#### 1. 依赖工具缺失
```bash
# 错误：command not found: jq
sudo apt-get install jq

# 错误：command not found: python3
sudo apt-get install python3 python3-pip
```

#### 2. GitHub API 错误
```bash
# 错误：API rate limit exceeded
# 解决：设置 GITHUB_TOKEN 环境变量

# 错误：Repository not found
# 解决：检查 repos.txt 中的仓库名称格式
```

#### 3. 文件权限问题
```bash
# 给脚本添加执行权限
chmod +x github_comments_stats.sh

# 检查配置文件是否可读
ls -la repos.txt users.txt
```

#### 4. 输出文件问题
```bash
# 错误：Permission denied writing to output file
# 解决：检查输出目录权限或更改输出路径
./github_comments_stats.sh 2023-01-01 2023-12-31 repos.txt users.txt ~/reports/output.xlsx
```

### 调试模式

启用详细输出进行调试：
```bash
# 启用 bash 调试模式
bash -x github_comments_stats.sh 2023-01-01 2023-12-31
```

## 📈 最佳实践

### 1. 数据收集策略
- **定期统计**：建议每月或每季度运行一次
- **增量更新**：使用时间范围避免重复统计
- **数据备份**：保存历史统计结果用于趋势分析

### 2. 配置文件管理
```bash
# 为不同项目创建专门的配置目录
mkdir -p configs/project-a
cp repos.txt configs/project-a/
cp users.txt configs/project-a/

# 使用专门配置运行
./github_comments_stats.sh 2023-01-01 2023-12-31 configs/project-a/repos.txt configs/project-a/users.txt
```

### 3. 自动化脚本示例
```bash
#!/bin/bash
# monthly_report.sh - 自动生成月度报告

YEAR=$(date +%Y)
MONTH=$(date +%m)
LAST_MONTH=$(date -d "last month" +%Y-%m)

# 生成上月报告
./github_comments_stats.sh ${LAST_MONTH}-01 ${LAST_MONTH}-31 \
    repos.txt users.txt "monthly_report_${LAST_MONTH}.xlsx"

echo "月度报告已生成：monthly_report_${LAST_MONTH}.xlsx"
```

## 🔒 安全注意事项

1. **Token 安全**：
   - 不要在脚本中硬编码 Token
   - 使用环境变量存储敏感信息
   - 定期轮换 GitHub Token

2. **文件权限**：
   ```bash
   # 设置适当的文件权限
   chmod 600 ~/.bashrc  # 如果在其中存储了 Token
   chmod 644 repos.txt users.txt
   chmod 755 github_comments_stats.sh
   ```

3. **数据隐私**：
   - 确保输出文件的访问权限
   - 考虑敏感仓库的访问控制

## 📞 技术支持

如果遇到问题，请检查：

1. **环境要求**：确保所有依赖工具已正确安装
2. **配置文件**：验证 repos.txt 和 users.txt 格式正确
3. **网络连接**：确保可以访问 GitHub API
4. **权限设置**：检查文件和目录权限

## 📄 许可证

本脚本遵循 MIT 许可证，可自由使用和修改。

---

**版本**：v2.0  
**最后更新**：2024年  
**维护者**：GitHub Comments Statistics Team 