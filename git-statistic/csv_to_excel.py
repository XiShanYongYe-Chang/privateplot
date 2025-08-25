#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os

def csv_to_excel_with_details(detail_csv, summary_csv, excel_file):
    """将详细CSV和汇总CSV文件转换为带两个工作表的Excel格式"""
    try:
        import pandas as pd
        
        # 读取CSV文件
        detail_df = pd.read_csv(detail_csv, encoding='utf-8')
        summary_df = pd.read_csv(summary_csv, encoding='utf-8')
        
        # 写入Excel文件
        with pd.ExcelWriter(excel_file, engine='openpyxl') as writer:
            # 详细数据工作表
            detail_df.to_excel(writer, index=False, sheet_name='详细贡献数据')
            
            # 汇总数据工作表  
            summary_df.to_excel(writer, index=False, sheet_name='汇总贡献统计')
            
            # 自动调整列宽
            for sheet_name in writer.sheets:
                worksheet = writer.sheets[sheet_name]
                for column in worksheet.columns:
                    max_length = 0
                    column_letter = column[0].column_letter
                    for cell in column:
                        try:
                            if len(str(cell.value)) > max_length:
                                max_length = len(str(cell.value))
                        except:
                            pass
                    adjusted_width = (max_length + 2) * 1.2
                    worksheet.column_dimensions[column_letter].width = min(adjusted_width, 50)
        
        print(f"✓ 成功转换为Excel文件: {excel_file}")
        print(f"  包含工作表: 详细贡献数据, 汇总贡献统计")
        return True
        
    except ImportError as e:
        print(f"错误: 缺少必要的Python库 - {e}")
        print("请安装: pip install pandas openpyxl")
        return False
    except Exception as e:
        print(f"错误: 转换失败 - {e}")
        return False

def csv_to_excel(csv_file, excel_file):
    """将单个CSV文件转换为Excel格式（向后兼容）"""
    try:
        import pandas as pd
        
        # 读取CSV文件
        df = pd.read_csv(csv_file, encoding='utf-8')
        
        # 写入Excel文件
        with pd.ExcelWriter(excel_file, engine='openpyxl') as writer:
            df.to_excel(writer, index=False, sheet_name='贡献统计')
            
            # 获取工作表
            worksheet = writer.sheets['贡献统计']
            
            # 自动调整列宽
            for column in worksheet.columns:
                max_length = 0
                column_letter = column[0].column_letter
                for cell in column:
                    try:
                        if len(str(cell.value)) > max_length:
                            max_length = len(str(cell.value))
                    except:
                        pass
                adjusted_width = (max_length + 2) * 1.2
                worksheet.column_dimensions[column_letter].width = min(adjusted_width, 50)
        
        print(f"✓ 成功转换为Excel文件: {excel_file}")
        return True
        
    except ImportError as e:
        print(f"错误: 缺少必要的Python库 - {e}")
        print("请安装: pip install pandas openpyxl")
        return False
    except Exception as e:
        print(f"错误: 转换失败 - {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) == 4:
        # 新模式：详细CSV + 汇总CSV -> Excel
        detail_csv = sys.argv[1]
        summary_csv = sys.argv[2]
        excel_file = sys.argv[3]
        
        if not os.path.exists(detail_csv):
            print(f"错误: 详细CSV文件不存在: {detail_csv}")
            sys.exit(1)
            
        if not os.path.exists(summary_csv):
            print(f"错误: 汇总CSV文件不存在: {summary_csv}")
            sys.exit(1)
        
        if csv_to_excel_with_details(detail_csv, summary_csv, excel_file):
            sys.exit(0)
        else:
            sys.exit(1)
            
    elif len(sys.argv) == 3:
        # 兼容模式：单个CSV -> Excel
        csv_file = sys.argv[1]
        excel_file = sys.argv[2]
        
        if not os.path.exists(csv_file):
            print(f"错误: CSV文件不存在: {csv_file}")
            sys.exit(1)
        
        if csv_to_excel(csv_file, excel_file):
            sys.exit(0)
        else:
            sys.exit(1)
    else:
        print("用法:")
        print("  python3 csv_to_excel.py <详细CSV文件> <汇总CSV文件> <输出Excel文件>")
        print("  python3 csv_to_excel.py <输入CSV文件> <输出Excel文件>")
        sys.exit(1) 