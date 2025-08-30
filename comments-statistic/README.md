# GitHub 多仓库评论统计脚本

这个脚本可以统计多个 GitHub 仓库中指定用户的评论数量，并生成 Excel 报告。

## 功能特性

- 支持同时统计多个 GitHub 仓库
- 从文件中读取仓库列表和用户列表
- 支持时间范围过滤
- 生成详细的 Excel 统计报告
- 支持 GitHub API 认证以提高请求限制

## 使用方法

```bash
./github_comments_stats.sh <start_date> <end_date> [repo_file] [user_file] [output_file]
```

### 参数说明

- `start_date`: 开始日期 (格式: YYYY-MM-DD，必填)
- `end_date`: 结束日期 (格式: YYYY-MM-DD，必填)
- `repo_file`: 仓库列表文件，每行格式为 `owner repo` (默认: 脚本目录下的 repos.txt)
- `user_file`: 用户列表文件 (默认: 脚本目录下的 users.txt)
- `output_file`: 输出Excel文件名 (默认: github_comments_stats.xlsx)

### 文件格式

#### 仓库列表文件 (repos.txt)
```
microsoft vscode
facebook react
google tensorflow
kubernetes kubernetes
nodejs node
```

#### 用户列表文件 (users.txt)
```
username1
username2
username3
```

### 使用示例

```bash
# 基本用法（使用默认的 repos.txt 和 users.txt）
./github_comments_stats.sh 2023-01-01 2023-12-31

# 指定仓库文件
./github_comments_stats.sh 2023-01-01 2023-12-31 my_repos.txt

# 指定仓库和用户文件
./github_comments_stats.sh 2023-01-01 2023-12-31 repos.txt my_users.txt

# 指定所有参数
./github_comments_stats.sh 2023-01-01 2023-12-31 repos.txt users.txt my_output.xlsx
```

## 环境要求

### 必需工具
- `bash`
- `curl`
- `jq` - JSON 处理工具
- `python3` - 用于生成 Excel 文件

### Python 依赖 (可选，用于生成 Excel)
```bash
pip3 install pandas openpyxl
```

如果没有安装 pandas 和 openpyxl，脚本会自动生成 CSV 文件作为替代。

## GitHub API 认证

为了避免 API 限制，建议设置 GitHub Token：

1. 访问 https://github.com/settings/tokens
2. 生成新的 Personal Access Token (选择 'public_repo' 权限即可)
3. 设置环境变量：
   ```bash
   export GITHUB_TOKEN=your_token_here
   ```

### API 限制
- 未认证：60 次/小时
- 已认证：5000 次/小时

## 输出格式

脚本会生成包含以下列的 Excel/CSV 文件：
- GitHub用户名
- 仓库名称
- 评论数

## 注意事项

1. 脚本会在请求之间添加 1 秒延迟以避免触发 API 限制
2. 大型仓库可能需要较长时间来完成统计
3. 确保仓库列表文件和用户列表文件格式正确
4. 私有仓库需要相应的访问权限

## 故障排除

### 常见错误

1. **"错误: 需要安装 jq 工具"**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # CentOS/RHEL
   sudo yum install jq
   
   # macOS
   brew install jq
   ```

2. **"错误: GitHub API返回了无效响应"**
   - 检查网络连接
   - 验证仓库名称是否正确
   - 检查 GitHub Token 是否有效

3. **API 限制错误**
   - 设置 GITHUB_TOKEN 环境变量
   - 减少并发请求或增加延迟时间

## 许可证

本脚本遵循 MIT 许可证。 