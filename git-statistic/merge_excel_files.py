#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Excel文件合并脚本
功能：
1. 将同一时间段的多个CSV文件合并为一个Excel文件
2. 计算每个用户在该时间段内的总贡献值
3. 按用户首字母排序
4. 删除中间生成的CSV文件
"""

import pandas as pd
import os
import sys
import glob
import re
from pathlib import Path
import argparse


def parse_filename(filename):
    """解析文件名获取时间段信息"""
    # 文件名格式: contributions_REPO_BRANCH_YYYY-MM-DD_YYYY-MM-DD.csv
    pattern = r'contributions_([^_]+)_([^_]+)_(\d{4}-\d{2}-\d{2})_(\d{4}-\d{2}-\d{2})\.csv'
    match = re.match(pattern, filename)
    if match:
        repo_name, branch_name, since_date, until_date = match.groups()
        return {
            'repo_name': repo_name,
            'branch_name': branch_name,
            'since_date': since_date,
            'until_date': until_date,
            'period': f"{since_date}_{until_date}"
        }
    return None


def merge_csv_files_by_period(csv_files, output_dir):
    """按时间段合并CSV文件"""
    # 按时间段分组文件
    period_files = {}
    
    for csv_file in csv_files:
        filename = os.path.basename(csv_file)
        file_info = parse_filename(filename)
        
        if file_info:
            period = file_info['period']
            if period not in period_files:
                period_files[period] = {
                    'files': [],
                    'since_date': file_info['since_date'],
                    'until_date': file_info['until_date']
                }
            period_files[period]['files'].append(csv_file)
    
    merged_files = []
    
    # 为每个时间段合并文件
    for period, info in period_files.items():
        print(f"正在合并时间段 {info['since_date']} 到 {info['until_date']} 的文件...")
        
        # 读取并合并所有CSV文件
        all_data = []
        
        for csv_file in info['files']:
            try:
                df = pd.read_csv(csv_file, encoding='utf-8')
                all_data.append(df)
                print(f"  - 读取文件: {os.path.basename(csv_file)}")
            except Exception as e:
                print(f"  - 警告: 无法读取文件 {csv_file}: {e}")
        
        if not all_data:
            print(f"  - 跳过时间段 {period}：没有有效的数据文件")
            continue
        
        # 合并所有数据
        combined_df = pd.concat(all_data, ignore_index=True)
        
        # 按用户名分组并汇总数据
        aggregated_df = combined_df.groupby('用户名').agg({
            '新增代码行数': 'sum',
            '删除代码行数': 'sum',
            '贡献代码总行数': 'sum',
            '代码提交次数': 'sum',
            '超大提交代码行数(>1800行/commit)': 'sum',
            '超大提交新增代码行数(>1800行/commit)': 'sum',
            '超大提交删除代码行数(>1800行/commit)': 'sum',
            '超大提交次数(>1800行/commit)': 'sum'
        }).reset_index()
        
        # 按用户名首字母排序（支持中文和英文）
        aggregated_df = aggregated_df.sort_values('用户名', key=lambda x: x.str.lower())
        
        # 生成输出文件名
        output_filename = f"contributions_merged_{info['since_date']}_{info['until_date']}.xlsx"
        output_path = os.path.join(output_dir, output_filename)
        
        # 保存为Excel文件
        try:
            with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
                aggregated_df.to_excel(writer, index=False, sheet_name='贡献统计')
                
                # 设置列宽自适应
                worksheet = writer.sheets['贡献统计']
                for column in worksheet.columns:
                    max_length = 0
                    column_letter = column[0].column_letter
                    for cell in column:
                        try:
                            if len(str(cell.value)) > max_length:
                                max_length = len(str(cell.value))
                        except:
                            pass
                    adjusted_width = min(max_length + 2, 50)
                    worksheet.column_dimensions[column_letter].width = adjusted_width
            
            print(f"  - 已生成合并文件: {output_filename}")
            print(f"  - 包含 {len(aggregated_df)} 个用户的数据")
            merged_files.append(output_path)
            
        except Exception as e:
            print(f"  - 错误: 无法保存Excel文件 {output_path}: {e}")
    
    return merged_files


def cleanup_csv_files(csv_files):
    """删除中间生成的CSV文件"""
    print("\n正在清理中间文件...")
    deleted_count = 0
    
    for csv_file in csv_files:
        try:
            os.remove(csv_file)
            print(f"  - 已删除: {os.path.basename(csv_file)}")
            deleted_count += 1
        except Exception as e:
            print(f"  - 警告: 无法删除文件 {csv_file}: {e}")
    
    print(f"共删除了 {deleted_count} 个中间文件")


def main():
    parser = argparse.ArgumentParser(description='合并CSV文件为Excel文件')
    parser.add_argument('--input-dir', '-i', default='.', help='CSV文件所在目录（默认为当前目录）')
    parser.add_argument('--output-dir', '-o', default='.', help='输出目录（默认为当前目录）')
    parser.add_argument('--pattern', '-p', default='contributions_*_*_????-??-??_????-??-??.csv', 
                        help='CSV文件名模式（默认匹配contributions文件）')
    parser.add_argument('--keep-csv', '-k', action='store_true', help='保留原始CSV文件')
    
    args = parser.parse_args()
    
    # 确保输出目录存在
    os.makedirs(args.output_dir, exist_ok=True)
    
    # 查找所有匹配的CSV文件
    pattern_path = os.path.join(args.input_dir, args.pattern)
    csv_files = glob.glob(pattern_path)
    
    if not csv_files:
        print(f"错误: 在目录 {args.input_dir} 中未找到匹配模式 {args.pattern} 的CSV文件")
        sys.exit(1)
    
    print(f"找到 {len(csv_files)} 个CSV文件")
    
    # 合并文件
    merged_files = merge_csv_files_by_period(csv_files, args.output_dir)
    
    if merged_files:
        print(f"\n成功生成 {len(merged_files)} 个合并的Excel文件:")
        for file_path in merged_files:
            print(f"  - {os.path.basename(file_path)}")
        
        # 清理中间文件（除非指定保留）
        if not args.keep_csv:
            cleanup_csv_files(csv_files)
        else:
            print("\n保留了原始CSV文件")
    else:
        print("\n未生成任何合并文件")
        sys.exit(1)


if __name__ == '__main__':
    main() 