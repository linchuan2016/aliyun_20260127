"""
强制初始化数据库（删除旧数据并重新创建）
用于修复服务器上的数据库问题
"""
import os
import sys
from database import SessionLocal, engine, Base
from models import User, Article, Book, Memo, Product

# 获取数据库路径
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "products.db")

def force_init():
    """强制初始化数据库"""
    db = SessionLocal()
    
    try:
        print("=" * 50)
        print("强制初始化数据库")
        print("=" * 50)
        print()
        
        # 1. 创建所有表
        print(">>> 步骤 1: 创建数据库表...")
        Base.metadata.create_all(bind=engine)
        print("✓ 数据库表创建完成")
        print()
        
        # 2. 清空现有数据（可选，谨慎使用）
        print(">>> 步骤 2: 检查现有数据...")
        article_count = db.query(Article).count()
        book_count = db.query(Book).count()
        print(f"当前文章数量: {article_count}")
        print(f"当前书籍数量: {book_count}")
        print()
        
        # 3. 如果数据为空，初始化数据
        if article_count == 0 or book_count == 0:
            print(">>> 步骤 3: 初始化数据...")
            from init_db import init_database
            init_database()
            print("✓ 数据初始化完成")
        else:
            print(">>> 步骤 3: 数据已存在，跳过初始化")
        
        # 4. 验证数据
        print()
        print(">>> 步骤 4: 验证数据...")
        article_count = db.query(Article).count()
        book_count = db.query(Book).count()
        print(f"文章数量: {article_count}")
        print(f"书籍数量: {book_count}")
        
        if article_count > 0 and book_count > 0:
            print("✓ 数据验证成功")
            return True
        else:
            print("✗ 数据验证失败")
            return False
        
    except Exception as e:
        db.rollback()
        print(f"✗ 错误: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    if force_init():
        print()
        print("=" * 50)
        print("✓ 数据库初始化成功！")
        print("=" * 50)
        sys.exit(0)
    else:
        print()
        print("=" * 50)
        print("✗ 数据库初始化失败！")
        print("=" * 50)
        sys.exit(1)

