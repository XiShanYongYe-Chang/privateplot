#!/bin/bash

# 脚本功能：定义贡献值查询相关的函数

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
}

function contributions-period-total-with-vendor {
  local result
  result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}"  --numstat |\
    sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$1+$2}END{print total}')
  echo "$result"
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
}

function contributions-period-addition-with-vendor {
  local result
  result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}"  --numstat |\
    sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$1}END{print total}')
  echo "$result"
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
}

function contributions-period-deletion-with-vendor {
  local result
  result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}"  --numstat |\
    sort -k3 |\
    grep -P "^\d+\t\d+" |\
    awk 'BEGIN{total=0}{total+=$2}END{print total}')
  echo "$result"
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period-commits {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --oneline | wc -l)
    echo "$result"
}

function contributions-period-commits-with-vendor {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --oneline | wc -l)
    echo "$result"
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period-large-commits-lines {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --numstat |\
        grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | grep -v "v1-" |\
        grep -v "reference" | grep -v "vendor" |\
        grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
        awk '
        BEGIN {
            current_commit = ""
            commit_lines = 0
            large_commits_total_lines = 0
        }
        /^commit [0-9a-f]{7,}/ {
            # 如果上一个commit的代码行数超过1800，累加其代码行数
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_lines += commit_lines
            }
            # 开始新的commit
            current_commit = $0
            commit_lines = 0
        }
        /^[0-9]+\t[0-9]+/ {
            # 累加代码行数（新增+删除）
            commit_lines += $1 + $2
        }
        END {
            # 检查最后一个commit
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_lines += commit_lines
            }
            print large_commits_total_lines
        }')
    echo "$result"
}

function contributions-period-large-commits-lines-with-vendor {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --numstat |\
        awk '
        BEGIN {
            current_commit = ""
            commit_lines = 0
            large_commits_total_lines = 0
        }
        /^commit [0-9a-f]{7,}/ {
            # 如果上一个commit的代码行数超过1800，累加其代码行数
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_lines += commit_lines
            }
            # 开始新的commit
            current_commit = $0
            commit_lines = 0
        }
        /^[0-9]+\t[0-9]+/ {
            # 累加代码行数（新增+删除）
            commit_lines += $1 + $2
        }
        END {
            # 检查最后一个commit
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_lines += commit_lines
            }
            print large_commits_total_lines
        }')
    echo "$result"
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period-large-commits-addition {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --numstat |\
        grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | grep -v "v1-" |\
        grep -v "reference" | grep -v "vendor" |\
        grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
        awk '
        BEGIN {
            current_commit = ""
            commit_lines = 0
            commit_addition = 0
            large_commits_total_addition = 0
        }
        /^commit [0-9a-f]{7,}/ {
            # 如果上一个commit的代码行数超过1800，累加其新增代码行数
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_addition += commit_addition
            }
            # 开始新的commit
            current_commit = $0
            commit_lines = 0
            commit_addition = 0
        }
        /^[0-9]+\t[0-9]+/ {
            # 累加代码行数（新增+删除）
            commit_lines += $1 + $2
            # 累加新增代码行数
            commit_addition += $1
        }
        END {
            # 检查最后一个commit
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_addition += commit_addition
            }
            print large_commits_total_addition
        }')
    echo "$result"
}

function contributions-period-large-commits-addition-with-vendor {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --numstat |\
        awk '
        BEGIN {
            current_commit = ""
            commit_lines = 0
            commit_addition = 0
            large_commits_total_addition = 0
        }
        /^commit [0-9a-f]{7,}/ {
            # 如果上一个commit的代码行数超过1800，累加其新增代码行数
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_addition += commit_addition
            }
            # 开始新的commit
            current_commit = $0
            commit_lines = 0
            commit_addition = 0
        }
        /^[0-9]+\t[0-9]+/ {
            # 累加代码行数（新增+删除）
            commit_lines += $1 + $2
            # 累加新增代码行数
            commit_addition += $1
        }
        END {
            # 检查最后一个commit
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_addition += commit_addition
            }
            print large_commits_total_addition
        }')
    echo "$result"
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period-large-commits-deletion {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --numstat |\
        grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | grep -v "v1-" |\
        grep -v "reference" | grep -v "vendor" |\
        grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
        awk '
        BEGIN {
            current_commit = ""
            commit_lines = 0
            commit_deletion = 0
            large_commits_total_deletion = 0
        }
        /^commit [0-9a-f]{7,}/ {
            # 如果上一个commit的代码行数超过1800，累加其删除代码行数
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_deletion += commit_deletion
            }
            # 开始新的commit
            current_commit = $0
            commit_lines = 0
            commit_deletion = 0
        }
        /^[0-9]+\t[0-9]+/ {
            # 累加代码行数（新增+删除）
            commit_lines += $1 + $2
            # 累加删除代码行数
            commit_deletion += $2
        }
        END {
            # 检查最后一个commit
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_deletion += commit_deletion
            }
            print large_commits_total_deletion
        }')
    echo "$result"
}

function contributions-period-large-commits-deletion-with-vendor {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --numstat |\
        awk '
        BEGIN {
            current_commit = ""
            commit_lines = 0
            commit_deletion = 0
            large_commits_total_deletion = 0
        }
        /^commit [0-9a-f]{7,}/ {
            # 如果上一个commit的代码行数超过1800，累加其删除代码行数
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_deletion += commit_deletion
            }
            # 开始新的commit
            current_commit = $0
            commit_lines = 0
            commit_deletion = 0
        }
        /^[0-9]+\t[0-9]+/ {
            # 累加代码行数（新增+删除）
            commit_lines += $1 + $2
            # 累加删除代码行数
            commit_deletion += $2
        }
        END {
            # 检查最后一个commit
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_total_deletion += commit_deletion
            }
            print large_commits_total_deletion
        }')
    echo "$result"
}

# AUTHOR="foo@bar.com"
# SINCE_DATE="2022-01-01"
# UNTIL_DATE="2023-01-01"
function contributions-period-large-commits-count {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --numstat |\
        grep -v "versioned_docs" | grep -v "infra/gen-resourcesdocs/" | grep -v "v1-" |\
        grep -v "reference" | grep -v "vendor" |\
        grep -Pv "Date:|insertion|deletion|file|Bin|\.svg|\.drawio|generated|yaml|\.json|html|go\.sum|\.pb\.go|\.pb-c|\=\>" |\
        awk '
        BEGIN {
            current_commit = ""
            commit_lines = 0
            large_commits_count = 0
        }
        /^commit [0-9a-f]{7,}/ {
            # 如果上一个commit的代码行数超过1800，计数加1
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_count++
            }
            # 开始新的commit
            current_commit = $0
            commit_lines = 0
        }
        /^[0-9]+\t[0-9]+/ {
            # 累加代码行数（新增+删除）
            commit_lines += $1 + $2
        }
        END {
            # 检查最后一个commit
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_count++
            }
            print large_commits_count
        }')
    echo "$result"
}

function contributions-period-large-commits-count-with-vendor {
    local result
    result=$(git log --no-merges --since ${SINCE_DATE} --until ${UNTIL_DATE} --author "${AUTHOR}" --numstat |\
        awk '
        BEGIN {
            current_commit = ""
            commit_lines = 0
            large_commits_count = 0
        }
        /^commit [0-9a-f]{7,}/ {
            # 如果上一个commit的代码行数超过1800，计数加1
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_count++
            }
            # 开始新的commit
            current_commit = $0
            commit_lines = 0
        }
        /^[0-9]+\t[0-9]+/ {
            # 累加代码行数（新增+删除）
            commit_lines += $1 + $2
        }
        END {
            # 检查最后一个commit
            if (current_commit != "" && commit_lines > 1800) {
                large_commits_count++
            }
            print large_commits_count
        }')
    echo "$result"
}
