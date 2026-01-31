"""
添加缺失的数据库列
用于修复服务器上的数据库结构问题
"""
import sqlite3
import os
import sys

# 获取数据库路径（存储在 data 文件夹）
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
DB_PATH = os.path.join(PROJECT_ROOT, "data", "products.db")

def add_missing_columns():
    """添加缺失的列"""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # 检查 articles 表结构
        cursor.execute("PRAGMA table_info(articles)")
        columns = [row[1] for row in cursor.fetchall()]
        print(f"articles 表当前字段: {columns}")
        
        # 添加 content_en 列（如果不存在）
        if 'content_en' not in columns:
            print("添加 content_en 列到 articles 表...")
            cursor.execute("ALTER TABLE articles ADD COLUMN content_en TEXT")
            print("✓ content_en 列已添加")
        else:
            print("✓ content_en 列已存在")
        
        # 添加 cover_image 列（如果不存在）
        if 'cover_image' not in columns:
            print("添加 cover_image 列到 articles 表...")
            cursor.execute("ALTER TABLE articles ADD COLUMN cover_image VARCHAR(1000)")
            print("✓ cover_image 列已添加")
        else:
            print("✓ cover_image 列已存在")
        
        # 检查 books 表结构
        cursor.execute("PRAGMA table_info(books)")
        columns = [row[1] for row in cursor.fetchall()]
        print(f"books 表当前字段: {columns}")
        
        # 添加 description 列（如果不存在）
        if 'description' not in columns:
            print("添加 description 列到 books 表...")
            cursor.execute("ALTER TABLE books ADD COLUMN description TEXT")
            print("✓ description 列已添加")
        else:
            print("✓ description 列已存在")
        
        conn.commit()
        print("\n✓ 所有缺失的列已添加完成")
        return True
        
    except Exception as e:
        conn.rollback()
        print(f"✗ 错误: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        conn.close()

if __name__ == "__main__":
    print("=" * 50)
    print("添加缺失的数据库列")
    print("=" * 50)
    print()
    
    if not os.path.exists(DB_PATH):
        print(f"✗ 数据库文件不存在: {DB_PATH}")
        sys.exit(1)
    
    if add_missing_columns():
        print("\n✓ 修复完成！")
        sys.exit(0)
    else:
        print("\n✗ 修复失败！")
        sys.exit(1)

