# Git 贡献统计脚本套件使用指南

这是一套用于统计多个Git仓库中开发者贡献情况的脚本工具，支持批量处理、时间段分析和Excel报告生成。

## 📋 目录结构

```
git-statistic/
├── generate-contributes.sh      # 单仓库贡献统计脚本
├── batch-generate-contributes.sh # 批量仓库贡献统计脚本
├── by-developer.sh              # 贡献统计函数库
├── csv_to_excel.py              # CSV转Excel工具
├── merge_excel_files.py         # Excel文件合并工具
├── repos.txt                    # 仓库配置文件
├── users.txt                    # 用户列表文件
├── time_periods.txt             # 时间段配置文件
└── README.md                    # 使用指南
```

## ✨ 功能特性

- 🏢 **多仓库支持**：批量统计多个Git仓库的贡献数据
- 📅 **时间段分析**：支持多个时间段的贡献统计对比
- 👥 **多用户统计**：同时统计多个开发者的贡献情况
- 📊 **详细报告**：生成包含详细数据和汇总统计的Excel报告
- 🔧 **灵活配置**：支持包含/排除vendor文件的统计选项
- 🚀 **批量处理**：自动化处理多个仓库和时间段
- 📈 **数据合并**：自动合并同时间段的多仓库数据
- 🛡️ **错误处理**：完善的错误检查和进度显示

## 🚀 快速开始

### 1. 环境准备

确保系统已安装必需工具：

```bash
# 基础工具
sudo apt-get update
sudo apt-get install git python3 python3-pip

# Python依赖
pip3 install pandas openpyxl
```

### 2. 配置文件设置

#### 仓库配置文件 (repos.txt)
每行包含：`<仓库目录路径> <分支名称> [远程仓库名称]`

```bash
# Karmada repos
/root/go/src/github.com/karmada-io/karmada master 
/root/go/src/github.com/karmada-io/dashboard main
/root/go/src/github.com/karmada-io/website main

# KubeEdge repos
/root/go/src/github.com/kubeedge/kubeedge master
/root/go/src/github.com/kubeedge/keink main

# 其他仓库...
```

#### 用户列表文件 (users.txt)
每行包含一个开发者的Git用户名或邮箱：

```
Shelley-BaoYue
RainbowMango
liaolecheng
zhzhuang-zju
changzhen
```

#### 时间段配置文件 (time_periods.txt)
每行包含一个时间段，格式：`开始日期,结束日期`

```
2025-01-01,2025-06-30
2025-07-01,2025-07-31
2025-08-01,2025-08-31
```

### 3. 基本使用

```bash
# 批量统计所有仓库（不包含vendor文件）
./batch-generate-contributes.sh false

# 批量统计所有仓库（包含vendor文件）
./batch-generate-contributes.sh true

# 单个仓库统计
./generate-contributes.sh /path/to/repo main false
```

## 📖 详细使用说明

### 主要脚本功能

#### 1. batch-generate-contributes.sh - 批量统计脚本

**功能**：批量处理多个仓库的贡献统计

**语法**：
```bash
./batch-generate-contributes.sh <是否包含vendor> [仓库配置文件] [时间段文件] [用户列表文件]
```

**参数说明**：
| 参数 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `是否包含vendor` | 必填 | true/false，是否统计vendor文件 | - |
| `仓库配置文件` | 可选 | 仓库列表配置文件 | repos.txt |
| `时间段文件` | 可选 | 时间段配置文件 | time_periods.txt |
| `用户列表文件` | 可选 | 用户列表文件 | users.txt |

**使用示例**：
```bash
# 基本用法
./batch-generate-contributes.sh false

# 指定配置文件
./batch-generate-contributes.sh true my_repos.txt my_periods.txt my_users.txt

# 只统计特定时间段
./batch-generate-contributes.sh false repos.txt q1_2025.txt
```

#### 2. generate-contributes.sh - 单仓库统计脚本

**功能**：统计单个仓库的贡献数据

**语法**：
```bash
./generate-contributes.sh <仓库目录> <分支名称> <是否包含vendor> [远程仓库名称] [时间段文件] [用户列表文件]
```

**参数说明**：
| 参数 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `仓库目录` | 必填 | Git仓库所在目录路径 | - |
| `分支名称` | 必填 | 要统计的分支名称 | - |
| `是否包含vendor` | 必填 | true/false，是否统计vendor文件 | - |
| `远程仓库名称` | 可选 | 远程仓库名称 | upstream |
| `时间段文件` | 可选 | 时间段配置文件 | time_periods.txt |
| `用户列表文件` | 可选 | 用户列表文件 | users.txt |

**使用示例**：
```bash
# 基本用法
./generate-contributes.sh /path/to/karmada main false

# 指定远程仓库
./generate-contributes.sh /path/to/karmada main true origin

# 指定所有参数
./generate-contributes.sh /path/to/karmada main false upstream periods.txt users.txt
```

#### 3. 辅助工具脚本

##### csv_to_excel.py - CSV转Excel工具

**功能**：将CSV文件转换为Excel格式，支持多工作表

**语法**：
```bash
python3 csv_to_excel.py <详细CSV文件> <汇总CSV文件> <输出Excel文件>
```

##### merge_excel_files.py - Excel合并工具

**功能**：合并同一时间段的多个CSV文件为单个Excel文件

**语法**：
```bash
python3 merge_excel_files.py [输出目录]
```

## 📊 输出说明

### 文件命名规则

生成的文件遵循以下命名规则：

```
contributions_<仓库名>_<分支名>_<开始日期>_<结束日期>.csv
contributions_<仓库名>_<分支名>_<开始日期>_<结束日期>_summary.csv
merged_<开始日期>_<结束日期>.xlsx
```

### 输出文件结构

#### 详细贡献数据 (CSV)
| 列名 | 说明 |
|------|------|
| 用户名 | 开发者用户名 |
| 仓库名 | 仓库名称 |
| 分支名 | 分支名称 |
| 时间段 | 统计时间段 |
| 总贡献值 | 代码行数变更总数 |
| 新增行数 | 新增代码行数 |
| 删除行数 | 删除代码行数 |
| 提交次数 | 提交数量 |

#### 汇总统计数据 (CSV)
| 列名 | 说明 |
|------|------|
| 用户名 | 开发者用户名 |
| 总贡献值 | 所有仓库总贡献值 |
| 总新增行数 | 所有仓库总新增行数 |
| 总删除行数 | 所有仓库总删除行数 |
| 总提交次数 | 所有仓库总提交次数 |
| 参与仓库数 | 参与的仓库数量 |

#### Excel报告 (XLSX)
- **详细贡献数据** 工作表：包含所有详细统计数据
- **汇总贡献统计** 工作表：包含用户汇总数据

## 🔧 高级配置

### 1. 自定义过滤规则

在 `by-developer.sh` 中可以自定义文件过滤规则：

```bash
# 排除特定文件类型和目录
grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | 
grep -v "v1-" | grep -v "reference" | grep -v "vendor" |
grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>"
```

### 2. 统计模式选择

#### 标准模式 (vendor=false)
- 排除vendor目录
- 排除生成文件
- 排除文档和配置文件
- 适用于代码贡献统计

#### 完整模式 (vendor=true)
- 包含所有文件
- 适用于完整项目贡献统计

### 3. 批量处理策略

```bash
# 按项目分组处理
mkdir -p reports/karmada reports/kubeedge

# 创建项目特定配置
echo "/root/go/src/github.com/karmada-io/karmada master" > karmada_repos.txt
echo "/root/go/src/github.com/karmada-io/dashboard main" >> karmada_repos.txt

# 分别统计
./batch-generate-contributes.sh false karmada_repos.txt
```

## 📈 使用场景示例

### 场景1：季度贡献报告

```bash
# 1. 配置季度时间段
cat > q1_2025.txt << EOF
2025-01-01,2025-03-31
EOF

# 2. 生成季度报告
./batch-generate-contributes.sh false repos.txt q1_2025.txt

# 3. 合并报告
python3 merge_excel_files.py
```

### 场景2：特定项目评估

```bash
# 1. 创建项目仓库列表
cat > karmada_repos.txt << EOF
/root/go/src/github.com/karmada-io/karmada master
/root/go/src/github.com/karmada-io/dashboard main
/root/go/src/github.com/karmada-io/website main
EOF

# 2. 创建核心开发者列表
cat > core_developers.txt << EOF
RainbowMango
liaolecheng
zhzhuang-zju
EOF

# 3. 统计核心开发者在Karmada项目的贡献
./batch-generate-contributes.sh false karmada_repos.txt time_periods.txt core_developers.txt
```

### 场景3：月度活跃度分析

```bash
# 1. 生成月度时间段
python3 -c "
import datetime
for month in range(1, 13):
    start = datetime.date(2025, month, 1)
    if month == 12:
        end = datetime.date(2025, 12, 31)
    else:
        end = datetime.date(2025, month+1, 1) - datetime.timedelta(days=1)
    print(f'{start},{end}')
" > monthly_2025.txt

# 2. 执行月度统计
./batch-generate-contributes.sh false repos.txt monthly_2025.txt

# 3. 生成月度报告
python3 merge_excel_files.py
```

## 🐛 故障排除

### 常见错误及解决方案

#### 1. Git仓库相关错误

```bash
# 错误：Not a git repository
# 解决：确保仓库路径正确且为Git仓库
cd /path/to/repo && git status

# 错误：Branch not found
# 解决：检查分支名称是否正确
git branch -a

# 错误：Remote not found
# 解决：检查远程仓库配置
git remote -v
```

#### 2. Python依赖错误

```bash
# 错误：ModuleNotFoundError: No module named 'pandas'
pip3 install pandas openpyxl

# 错误：Permission denied
sudo pip3 install pandas openpyxl
```

#### 3. 文件权限问题

```bash
# 给脚本添加执行权限
chmod +x *.sh

# 检查配置文件权限
ls -la *.txt
```

#### 4. 配置文件格式错误

```bash
# 检查repos.txt格式
# 正确格式：路径 分支名 [远程名]
/path/to/repo main upstream

# 检查time_periods.txt格式  
# 正确格式：开始日期,结束日期
2025-01-01,2025-01-31

# 检查users.txt格式
# 每行一个用户名
username1
username2
```

### 调试模式

启用详细输出进行调试：

```bash
# 启用bash调试模式
bash -x batch-generate-contributes.sh false

# 查看Git日志
git log --oneline --since="2025-01-01" --until="2025-01-31" --author="username"
```

## 📈 最佳实践

### 1. 数据收集策略

- **定期统计**：建议每月运行一次批量统计
- **增量更新**：使用时间段避免重复统计历史数据
- **数据备份**：定期备份生成的Excel报告

### 2. 性能优化

```bash
# 并行处理多个仓库（小心资源使用）
# 修改batch脚本支持并行处理
for repo_config in "${repo_configs[@]}"; do
    (
        # 仓库处理逻辑
    ) &
done
wait
```

### 3. 自动化脚本示例

```bash
#!/bin/bash
# weekly_report.sh - 自动生成周报

WEEK_START=$(date -d "last monday" +%Y-%m-%d)
WEEK_END=$(date -d "last sunday" +%Y-%m-%d)

# 创建周报时间段文件
echo "$WEEK_START,$WEEK_END" > weekly_period.txt

# 生成周报
./batch-generate-contributes.sh false repos.txt weekly_period.txt

# 合并报告
python3 merge_excel_files.py

echo "周报已生成：merged_${WEEK_START}_${WEEK_END}.xlsx"
```

### 4. 配置文件管理

```bash
# 为不同团队创建专门配置
mkdir -p configs/{frontend,backend,devops}

# 前端团队配置
cp repos.txt configs/frontend/
echo "alice\nbob\ncharlie" > configs/frontend/users.txt

# 使用团队配置
./batch-generate-contributes.sh false configs/frontend/repos.txt time_periods.txt configs/frontend/users.txt
```

## 🔒 安全注意事项

1. **仓库访问权限**：
   - 确保对所有配置的仓库有读取权限
   - 私有仓库需要适当的SSH密钥或访问令牌

2. **文件权限**：
   ```bash
   # 设置适当的文件权限
   chmod 755 *.sh
   chmod 644 *.txt *.py
   ```

3. **数据隐私**：
   - 生成的报告可能包含敏感的开发数据
   - 确保输出文件的访问权限设置正确

## 📞 技术支持

如果遇到问题，请检查：

1. **Git仓库状态**：确保所有仓库都是有效的Git仓库
2. **分支存在性**：验证配置的分支名称是否正确
3. **用户名匹配**：确保用户名与Git提交记录中的作者信息匹配
4. **时间格式**：验证时间段格式为YYYY-MM-DD
5. **Python环境**：确保pandas和openpyxl已正确安装

## 📄 许可证

本脚本套件遵循 MIT 许可证，可自由使用和修改。

---

**版本**：v1.0  
**最后更新**：2024年  
**维护者**：Git Statistics Team 