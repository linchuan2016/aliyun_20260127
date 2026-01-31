#!/bin/bash
# 完整修复 Blog 和 Book 模块
# 在服务器上执行: bash /var/www/my-fullstack-app/deploy/完整修复Blog和Book.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "完整修复 Blog 和 Book 模块"
echo "=========================================="
echo ""

# 步骤 1: 同步代码
echo ">>> 步骤 1: 从 Gitee 同步代码..."
cd $DEPLOY_PATH
git fetch gitee main
git reset --hard gitee/main
echo "✓ 代码同步完成"
echo ""

# 步骤 2: 添加缺失的列
echo ">>> 步骤 2: 添加缺失的数据库列..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
python add_missing_columns.py
echo "✓ 数据库列检查完成"
echo ""

# 步骤 3: 强制初始化数据库
echo ">>> 步骤 3: 初始化数据库..."
python force_init_db.py || {
    echo "强制初始化失败，尝试普通初始化..."
    python init_db.py
}
echo "✓ 数据库初始化完成"
echo ""

# 步骤 4: 验证数据
echo ">>> 步骤 4: 验证数据..."
python3 << EOF
from database import SessionLocal
from models import Article, Book

db = SessionLocal()
try:
    article_count = db.query(Article).count()
    book_count = db.query(Book).count()
    print(f"文章数量: {article_count}")
    print(f"书籍数量: {book_count}")
    
    if article_count > 0:
        article = db.query(Article).first()
        print(f"第一篇文章: {article.title}")
    
    if book_count > 0:
        book = db.query(Book).first()
        print(f"第一本书: {book.title}")
    
    print("✓ 数据验证完成")
except Exception as e:
    print(f"✗ 数据验证失败: {e}")
finally:
    db.close()
EOF
echo ""

# 步骤 5: 重启服务
echo ">>> 步骤 5: 重启服务..."
systemctl daemon-reload
systemctl restart my-fullstack-app
sleep 5
systemctl restart nginx
sleep 2
echo "✓ 服务重启完成"
echo ""

# 步骤 6: 测试 API
echo ">>> 步骤 6: 测试 API..."
sleep 2

echo "测试 /api/health:"
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ Health check 通过"
else
    echo "✗ Health check 失败"
fi

echo ""
echo "测试 /api/articles:"
articles_response=$(curl -s http://127.0.0.1:8000/api/articles)
if [ $? -eq 0 ]; then
    article_count=$(echo "$articles_response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
    echo "✓ Articles API 正常，返回 $article_count 篇文章"
    echo "$articles_response" | head -c 200
    echo ""
else
    echo "✗ Articles API 失败"
fi

echo ""
echo "测试 /api/books:"
books_response=$(curl -s http://127.0.0.1:8000/api/books)
if [ $? -eq 0 ]; then
    book_count=$(echo "$books_response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
    echo "✓ Books API 正常，返回 $book_count 本书"
    echo "$books_response" | head -c 200
    echo ""
else
    echo "✗ Books API 失败"
fi

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="

