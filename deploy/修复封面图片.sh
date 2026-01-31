#!/bin/bash
# 修复封面图片显示问题
# 在服务器上执行: bash /var/www/my-fullstack-app/deploy/修复封面图片.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "修复封面图片显示问题"
echo "=========================================="
echo ""

# 步骤 1: 同步代码
echo ">>> 步骤 1: 从 Gitee 同步代码..."
cd $DEPLOY_PATH
git fetch gitee main
git reset --hard gitee/main
echo "✓ 代码同步完成"
echo ""

# 步骤 2: 检查封面图片文件
echo ">>> 步骤 2: 检查封面图片文件..."
if [ ! -d "$DEPLOY_PATH/frontend/public/book-covers" ]; then
    mkdir -p "$DEPLOY_PATH/frontend/public/book-covers"
    echo "✓ 创建 book-covers 目录"
fi

if [ ! -d "$DEPLOY_PATH/frontend/public/article-covers" ]; then
    mkdir -p "$DEPLOY_PATH/frontend/public/article-covers"
    echo "✓ 创建 article-covers 目录"
fi

# 检查图片文件是否存在
if [ ! -f "$DEPLOY_PATH/frontend/public/book-covers/s3259913.jpg" ]; then
    echo "⚠  s3259913.jpg 不存在，需要下载"
fi

if [ ! -f "$DEPLOY_PATH/frontend/public/book-covers/s1070959.jpg" ]; then
    echo "⚠  s1070959.jpg 不存在，需要下载"
fi

if [ ! -f "$DEPLOY_PATH/frontend/public/article-covers/Steam.jpg" ]; then
    echo "⚠  Steam.jpg 不存在，需要下载"
fi

echo "✓ 封面图片目录检查完成"
echo ""

# 步骤 3: 更新数据库中的封面路径
echo ">>> 步骤 3: 更新数据库中的封面路径..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
python update_cover_images.py
echo "✓ 封面路径更新完成"
echo ""

# 步骤 4: 重新构建前端（确保图片文件被包含）
echo ">>> 步骤 4: 重新构建前端..."
cd $DEPLOY_PATH/frontend
export NODE_OPTIONS='--max-old-space-size=2048'
npm run build
echo "✓ 前端构建完成"
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

# 步骤 6: 验证
echo ">>> 步骤 6: 验证封面图片..."
echo "检查静态文件目录:"
ls -la $DEPLOY_PATH/frontend/dist/book-covers/ 2>/dev/null || echo "book-covers 目录不存在于 dist"
ls -la $DEPLOY_PATH/frontend/dist/article-covers/ 2>/dev/null || echo "article-covers 目录不存在于 dist"
echo ""

echo "测试 API:"
curl -s http://127.0.0.1:8000/api/books | python3 -c "import sys, json; data=json.load(sys.stdin); [print(f\"Book: {b['title']}, Cover: {b.get('cover_image', 'None')}\") for b in data]" 2>/dev/null || echo "API 测试失败"
echo ""

echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "注意：如果封面图片文件不存在，需要："
echo "1. 从本地复制图片文件到服务器"
echo "2. 或运行 download_book_covers.py 下载图片"
echo ""

