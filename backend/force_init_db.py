"""
强制初始化数据库（删除旧数据并重新创建）
用于修复服务器上的数据库问题
"""
import os
import sys
from database import SessionLocal, engine, Base
from models import User, Article, Book, Memo, Product

# 获取数据库路径（存储在 data 文件夹）
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(BASE_DIR)
DB_PATH = os.path.join(PROJECT_ROOT, "data", "products.db")

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
        
        # 3. 初始化数据（如果缺失）
        if article_count == 0 or book_count == 0:
            print(">>> 步骤 3: 初始化数据...")
            # 如果书籍数据缺失，直接初始化书籍
            if book_count == 0:
                print("初始化书籍数据...")
                from datetime import datetime
                
                # 添加《异类》
                book1 = Book(
                    title="异类",
                    cover_image="/data/book-covers/s3259913.jpg",
                    author="马尔科姆·格拉德威尔（Malcolm Gladwell）",
                    publish_date=datetime(2009, 4, 1),
                    description="在《异类》一书中，格拉德威尔对社会中那些成功人士进行的分析，让读者看到了一连串颇感意外的统计结果。这本书要告诉读者的是：如果没有机遇和文化、环境因素，即便是智商超过爱因斯坦，也只能做一份平庸的工作。"
                )
                db.add(book1)
                
                # 添加《枪炮、病菌与钢铁：人类社会的命运》
                book2 = Book(
                    title="枪炮、病菌与钢铁：人类社会的命运",
                    cover_image="/data/book-covers/s1070959.jpg",
                    author="贾雷德·戴蒙德（Jared Diamond）",
                    publish_date=datetime(2000, 8, 1),
                    description="为什么是欧亚大陆人征服、赶走或大批杀死印第安人、澳大利亚人和非洲人，而不是相反？为什么小麦和玉米、牛和猪以及现代世界的其他一些'了不起的'作物和牲畜出现在这些特定地区，而不是其他地区？在这部开创性的著作中，演化生物学家贾雷德·戴蒙德揭示了事实上有助于形成历史最广泛模式的环境因素，从而以震撼人心的力量摧毁了以种族主义为基础的人类史理论。"
                )
                db.add(book2)
                db.commit()
                print("✓ 书籍数据初始化完成")
            
            # 如果文章数据缺失，调用 init_db
            if article_count == 0:
                print("初始化文章数据...")
                from init_db import init_db
                init_db()
                print("✓ 文章数据初始化完成")
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

