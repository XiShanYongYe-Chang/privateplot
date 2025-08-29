# GitHub评论统计脚本

这个脚本用于统计GitHub用户在指定仓库中某段时间内的评论数量，并将结果输出到Excel文件。

## 功能特点

- 从用户列表文件读取需要统计的GitHub用户名
- 支持指定时间范围进行统计
- 自动分页获取所有评论数据
- 优化API请求次数，每次请求后统计所有用户的评论
- 输出Excel格式的统计报告
- 包含详细的统计摘要

## 依赖要求

在运行脚本之前，请确保安装了以下工具：

```bash
# 安装jq（JSON处理工具）
sudo apt-get install jq  # Ubuntu/Debian
# 或
sudo yum install jq       # CentOS/RHEL

# 安装Python3和pip
sudo apt-get install python3 python3-pip

# 安装Python依赖包
pip3 install pandas openpyxl
```

## 使用方法

### 基本语法

```bash
./github_comments_stats.sh <owner> <repo> [start_date] [end_date] [user_file] [output_file]
```

### 参数说明

- `owner` - GitHub组织或用户名（必填）
- `repo` - 仓库名称（必填）
- `start_date` - 开始日期，格式：YYYY-MM-DD（可选）
- `end_date` - 结束日期，格式：YYYY-MM-DD（可选）
- `user_file` - 用户列表文件（可选，默认：users.txt）
- `output_file` - 输出Excel文件名（可选，默认：github_comments_stats.xlsx）

### 使用示例

1. **基本使用**（统计所有时间的评论）：
```bash
./github_comments_stats.sh microsoft vscode
```

2. **指定时间范围**：
```bash
./github_comments_stats.sh microsoft vscode 2023-01-01 2023-12-31
```

3. **自定义用户文件和输出文件**：
```bash
./github_comments_stats.sh microsoft vscode 2023-01-01 2023-12-31 my_users.txt my_output.xlsx
```

## 用户文件格式

用户文件应该是一个文本文件，每行包含一个GitHub用户名：

```
XiShanYongYe-Chang
user1
user2
anotheruser
```

## 输出文件格式

生成的Excel文件包含以下三列：

| GitHub用户名 | 仓库名称 | 评论数 |
|-------------|----------|--------|
| XiShanYongYe-Chang | microsoft/vscode | 15 |
| user1 | microsoft/vscode | 3 |
| user2 | microsoft/vscode | 0 |

## GitHub Token 设置（重要！）

为了避免API限制问题，**强烈建议**设置GitHub Personal Access Token：

### 快速设置
```bash
# 运行Token设置助手
./setup_token.sh
```

### 手动设置
1. 访问 https://github.com/settings/tokens
2. 生成新的Token（选择 'public_repo' 权限）
3. 设置环境变量：
   ```bash
   export GITHUB_TOKEN=your_token_here
   ```

### API限制对比
- **未认证**: 60次/小时 ⚠️ 
- **已认证**: 5000次/小时 ✅

## 注意事项

1. **API限制**：
   - 未认证的GitHub API每小时限制60次请求
   - 使用Token后可提升到5000次/小时
   - 脚本会自动检测Token并使用认证API

2. **大型仓库**：对于有大量评论的仓库，统计可能需要较长时间
3. **网络连接**：确保有稳定的网络连接以访问GitHub API
4. **调试功能**：如遇问题，可使用 `./debug_api.sh owner repo` 进行诊断

## 故障排除

### 常见问题

1. **API rate limit exceeded** 错误：
   ```bash
   # 设置GitHub Token解决
   ./setup_token.sh
   ```

2. **jq: command not found** 错误：
   ```bash
   sudo apt-get install jq  # Ubuntu/Debian
   ```

3. **Python模块导入错误**：
   ```bash
   pip3 install pandas openpyxl
   ```

4. **获取评论数量很少**：
   ```bash
   # 使用调试脚本检查
   ./debug_api.sh owner repo
   ```

5. **无法生成Excel文件**：
   - 脚本会自动生成CSV文件作为替代
   - 检查pandas和openpyxl是否正确安装

### 工具脚本

- `./setup_token.sh` - GitHub Token设置助手
- `./debug_api.sh owner repo` - API调试工具
- `./example_usage.sh` - 使用示例和依赖检查

## 许可证

MIT License 