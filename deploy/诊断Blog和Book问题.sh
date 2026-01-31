#!/bin/bash
# 诊断 Blog 和 Book 模块问题
# 在服务器上执行: bash /var/www/my-fullstack-app/deploy/诊断Blog和Book问题.sh

echo "=========================================="
echo "诊断 Blog 和 Book 模块问题"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 1. 检查后端服务状态
echo ">>> 1. 检查后端服务状态..."
systemctl status my-fullstack-app --no-pager -l | head -20
echo ""

# 2. 检查后端日志
echo ">>> 2. 检查后端服务日志（最近20行）..."
journalctl -u my-fullstack-app -n 20 --no-pager
echo ""

# 3. 测试 API 端点
echo ">>> 3. 测试 API 端点..."
echo "测试 /api/health:"
curl -s http://127.0.0.1:8000/api/health || echo "✗ Health check failed"
echo ""
echo "测试 /api/articles:"
curl -s http://127.0.0.1:8000/api/articles | head -c 200 || echo "✗ Articles API failed"
echo ""
echo "测试 /api/books:"
curl -s http://127.0.0.1:8000/api/books | head -c 200 || echo "✗ Books API failed"
echo ""

# 4. 检查数据库
echo ">>> 4. 检查数据库..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
python3 << EOF
from database import SessionLocal, engine
from models import Article, Book
from sqlalchemy import inspect

try:
    # 检查表是否存在
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f"数据库表: {tables}")
    
    # 检查数据
    db = SessionLocal()
    article_count = db.query(Article).count()
    book_count = db.query(Book).count()
    print(f"文章数量: {article_count}")
    print(f"书籍数量: {book_count}")
    
    # 检查表结构
    if 'articles' in tables:
        columns = [col['name'] for col in inspector.get_columns('articles')]
        print(f"articles 表字段: {columns}")
    
    if 'books' in tables:
        columns = [col['name'] for col in inspector.get_columns('books')]
        print(f"books 表字段: {columns}")
    
    db.close()
    print("✓ 数据库检查完成")
except Exception as e:
    print(f"✗ 数据库检查失败: {e}")
    import traceback
    traceback.print_exc()
EOF
echo ""

# 5. 检查代码版本
echo ">>> 5. 检查代码版本..."
cd $DEPLOY_PATH
echo "当前 Git 提交:"
git log -1 --oneline
echo ""
echo "检查关键文件是否存在:"
ls -la backend/main.py backend/models.py backend/schemas.py 2>&1
echo ""

# 6. 检查 Python 导入
echo ">>> 6. 检查 Python 模块导入..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
python3 << EOF
try:
    from models import Article, Book
    print("✓ Article 和 Book 模型导入成功")
    
    from schemas import ArticleResponse, BookResponse
    print("✓ ArticleResponse 和 BookResponse 导入成功")
    
    from main import app
    print("✓ main 模块导入成功")
    
    print("✓ 所有模块导入正常")
except Exception as e:
    print(f"✗ 模块导入失败: {e}")
    import traceback
    traceback.print_exc()
EOF
echo ""

echo "=========================================="
echo "诊断完成"
echo "=========================================="

