#!/bin/bash
# 诊断文章同步问题
# 在服务器上执行: bash deploy/诊断文章同步问题.sh

echo "=========================================="
echo "诊断文章同步问题"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 1. 检查 data/articles.json 文件
echo ">>> 1. 检查 data/articles.json 文件..."
if [ -f "$DEPLOY_PATH/data/articles.json" ]; then
    echo "✓ 文件存在"
    FILE_SIZE=$(stat -f%z "$DEPLOY_PATH/data/articles.json" 2>/dev/null || stat -c%s "$DEPLOY_PATH/data/articles.json" 2>/dev/null || echo "unknown")
    echo "  文件大小: $FILE_SIZE 字节"
    ARTICLE_COUNT=$(python3 -c "import json; f=open('$DEPLOY_PATH/data/articles.json', 'r', encoding='utf-8'); data=json.load(f); print(len(data))" 2>/dev/null || echo "无法读取")
    echo "  文章数量: $ARTICLE_COUNT"
    echo ""
    echo "  文件内容预览（前500字符）:"
    head -c 500 "$DEPLOY_PATH/data/articles.json" 2>/dev/null || cat "$DEPLOY_PATH/data/articles.json" | head -c 500
    echo ""
    echo ""
else
    echo "✗ 文件不存在: $DEPLOY_PATH/data/articles.json"
    echo "  需要从 Gitee 拉取最新代码"
    echo ""
fi

# 2. 检查数据库中的文章
echo ">>> 2. 检查数据库中的文章..."
cd "$DEPLOY_PATH/backend"
source ../venv/bin/activate

python3 << 'EOF'
from database import SessionLocal
from models import Article
import sys

try:
    db = SessionLocal()
    article_count = db.query(Article).count()
    print(f"✓ 数据库连接成功")
    print(f"  文章总数: {article_count}")
    
    if article_count > 0:
        articles = db.query(Article).limit(5).all()
        print(f"\n  前5篇文章:")
        for article in articles:
            print(f"    - {article.title} (ID: {article.id}, 发布时间: {article.publish_date})")
    else:
        print("  ⚠ 数据库中没有文章")
    
    db.close()
except Exception as e:
    print(f"✗ 数据库检查失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
EOF

echo ""

# 3. 尝试手动导入
echo ">>> 3. 尝试手动导入文章..."
if [ -f "$DEPLOY_PATH/data/articles.json" ]; then
    cd "$DEPLOY_PATH/backend"
    source ../venv/bin/activate
    python3 import_articles.py
    echo ""
else
    echo "⚠ 跳过导入（文件不存在）"
    echo ""
fi

# 4. 再次检查数据库
echo ">>> 4. 再次检查数据库中的文章..."
cd "$DEPLOY_PATH/backend"
source ../venv/bin/activate

python3 << 'EOF'
from database import SessionLocal
from models import Article

try:
    db = SessionLocal()
    article_count = db.query(Article).count()
    print(f"  文章总数: {article_count}")
    
    if article_count > 0:
        articles = db.query(Article).all()
        print(f"\n  所有文章列表:")
        for article in articles:
            print(f"    - {article.title} (发布时间: {article.publish_date})")
    else:
        print("  ✗ 数据库仍然没有文章")
    
    db.close()
except Exception as e:
    print(f"✗ 检查失败: {e}")
EOF

echo ""
echo "=========================================="
echo "诊断完成"
echo "=========================================="

