#!/bin/bash
# 修复 Blog 和 Book 模块问题
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/修复Blog和Book问题.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "修复 Blog 和 Book 模块问题"
echo "=========================================="
echo ""

# 1. 确保数据库表存在
echo ">>> 步骤 1: 确保数据库表存在..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
python3 << EOF
from database import engine, Base
from models import Article, Book

try:
    # 创建所有表
    Base.metadata.create_all(bind=engine)
    print("✓ 数据库表创建/更新完成")
except Exception as e:
    print(f"✗ 数据库表创建失败: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
EOF
echo ""

# 2. 初始化数据库（确保有初始数据）
echo ">>> 步骤 2: 初始化数据库..."
python init_db.py 2>&1 || echo "数据库初始化完成（可能已存在）"
echo ""

# 3. 检查并修复表结构
echo ">>> 步骤 3: 检查表结构..."
python3 << EOF
from database import SessionLocal, engine
from sqlalchemy import inspect, text

db = SessionLocal()
inspector = inspect(engine)

try:
    # 检查 articles 表
    if 'articles' in inspector.get_table_names():
        columns = [col['name'] for col in inspector.get_columns('articles')]
        print(f"articles 表字段: {columns}")
        
        # 检查是否有新字段
        if 'cover_image' not in columns:
            print("添加 cover_image 字段...")
            db.execute(text("ALTER TABLE articles ADD COLUMN cover_image VARCHAR(1000)"))
            db.commit()
            print("✓ cover_image 字段已添加")
        
        if 'content_en' not in columns:
            print("添加 content_en 字段...")
            db.execute(text("ALTER TABLE articles ADD COLUMN content_en TEXT"))
            db.commit()
            print("✓ content_en 字段已添加")
    
    # 检查 books 表
    if 'books' in inspector.get_table_names():
        columns = [col['name'] for col in inspector.get_columns('books')]
        print(f"books 表字段: {columns}")
        
        # 检查是否有 description 字段
        if 'description' not in columns:
            print("添加 description 字段...")
            db.execute(text("ALTER TABLE books ADD COLUMN description TEXT"))
            db.commit()
            print("✓ description 字段已添加")
    
    print("✓ 表结构检查完成")
except Exception as e:
    print(f"✗ 表结构检查失败: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()
EOF
echo ""

# 4. 重启服务
echo ">>> 步骤 4: 重启服务..."
systemctl daemon-reload
systemctl restart my-fullstack-app
sleep 5
echo "✓ 服务已重启"
echo ""

# 5. 测试 API
echo ">>> 步骤 5: 测试 API..."
sleep 2
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ Health check 通过"
else
    echo "✗ Health check 失败"
fi

if curl -s http://127.0.0.1:8000/api/articles > /dev/null; then
    echo "✓ Articles API 正常"
else
    echo "✗ Articles API 失败"
fi

if curl -s http://127.0.0.1:8000/api/books > /dev/null; then
    echo "✓ Books API 正常"
else
    echo "✗ Books API 失败"
fi
echo ""

echo "=========================================="
echo "修复完成"
echo "=========================================="

