#!/bin/bash
# 修复文章同步问题
# 在服务器上执行: bash deploy/修复文章同步.sh

set -e

echo "=========================================="
echo "修复文章同步问题"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 步骤 1: 确保代码是最新的
echo ">>> 步骤 1: 拉取最新代码..."
cd "$DEPLOY_PATH"
git stash push -m "backup-$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
git fetch gitee main
git reset --hard gitee/main
echo "✓ 代码已更新"
echo ""

# 步骤 2: 检查 data/articles.json
echo ">>> 步骤 2: 检查 data/articles.json..."
if [ ! -f "$DEPLOY_PATH/data/articles.json" ]; then
    echo "✗ 文件不存在，尝试创建目录..."
    mkdir -p "$DEPLOY_PATH/data"
    echo "⚠ 如果文件仍然不存在，请确保已提交到 Git"
else
    echo "✓ 文件存在"
    ARTICLE_COUNT=$(python3 -c "import json; f=open('$DEPLOY_PATH/data/articles.json', 'r', encoding='utf-8'); data=json.load(f); print(len(data))" 2>/dev/null || echo "0")
    echo "  文章数量: $ARTICLE_COUNT"
fi
echo ""

# 步骤 3: 激活虚拟环境并导入文章
echo ">>> 步骤 3: 导入文章数据..."
cd "$DEPLOY_PATH/backend"
source ../venv/bin/activate

# 确保 import_articles.py 存在
if [ ! -f "import_articles.py" ]; then
    echo "✗ import_articles.py 不存在，请确保代码已同步"
    exit 1
fi

# 执行导入
python3 import_articles.py
if [ $? -eq 0 ]; then
    echo "✓ 文章导入成功"
else
    echo "✗ 文章导入失败"
    exit 1
fi
echo ""

# 步骤 4: 验证导入结果
echo ">>> 步骤 4: 验证导入结果..."
python3 << 'EOF'
from database import SessionLocal
from models import Article

db = SessionLocal()
article_count = db.query(Article).count()
print(f"数据库中的文章总数: {article_count}")

if article_count > 0:
    articles = db.query(Article).all()
    print("\n文章列表:")
    for article in articles:
        print(f"  - {article.title}")
else:
    print("⚠ 警告: 数据库中没有文章")

db.close()
EOF

echo ""

# 步骤 5: 重启服务
echo ">>> 步骤 5: 重启服务..."
sudo systemctl restart my-fullstack-app
sleep 3
echo "✓ 服务已重启"
echo ""

# 步骤 6: 测试 API
echo ">>> 步骤 6: 测试 API..."
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/articles 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ API 正常 (HTTP $HTTP_CODE)"
    ARTICLE_COUNT_API=$(curl -s http://127.0.0.1:8000/api/articles | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "0")
    echo "  API 返回文章数量: $ARTICLE_COUNT_API"
else
    echo "✗ API 异常 (HTTP $HTTP_CODE)"
    echo "查看日志: journalctl -u my-fullstack-app -n 50 --no-pager"
fi
echo ""

echo "=========================================="
echo "修复完成"
echo "=========================================="
echo ""
echo "如果问题仍然存在，请检查:"
echo "1. data/articles.json 文件内容是否正确"
echo "2. 数据库连接是否正常"
echo "3. 后端服务日志: journalctl -u my-fullstack-app -n 100 --no-pager"

