#!/bin/bash
# 更新前端代码并重新构建
# 使用方法: sudo bash update-frontend.sh

set -e

echo "========================================"
echo "  更新前端代码并重新构建"
echo "========================================"
echo ""

APP_DIR="/var/www/my-fullstack-app"

# 1. 拉取最新代码
echo "[1/4] 拉取最新代码..."
cd $APP_DIR

if git pull gitee main 2>/dev/null; then
    echo "  ✓ 从 Gitee 拉取成功"
elif git pull origin main 2>/dev/null; then
    echo "  ✓ 从 GitHub 拉取成功"
else
    echo "  ⚠️  Git 拉取失败，使用现有代码"
fi

# 2. 检查前端源代码
echo "[2/4] 检查前端源代码..."
if grep -q "无法连接到后端!2026.01.28" $APP_DIR/frontend/src/App.vue 2>/dev/null || \
   grep -q "无法连接到后端！2026.01.28" $APP_DIR/frontend/src/App.vue 2>/dev/null; then
    echo "  ✓ 前端源代码已更新（包含新日期）"
else
    echo "  ⚠️  前端源代码可能未更新，检查文件..."
    echo "  当前 App.vue 内容："
    grep -A 5 "无法连接到后端" $APP_DIR/frontend/src/App.vue || echo "  未找到错误消息"
fi

# 3. 重新构建前端
echo "[3/4] 重新构建前端..."
cd $APP_DIR/frontend

# 删除旧的构建文件
rm -rf dist

# 重新构建
npm run build

# 检查构建结果
if [ -f "dist/index.html" ]; then
    echo "  ✓ 前端构建成功"
    echo "  构建文件时间："
    ls -lth dist/ | head -5
else
    echo "  ✗ 前端构建失败"
    exit 1
fi

# 4. 检查构建后的文件内容
echo "[4/4] 验证构建文件..."
if grep -r "无法连接到后端!2026.01.28" dist/ 2>/dev/null || \
   grep -r "无法连接到后端！2026.01.28" dist/ 2>/dev/null; then
    echo "  ✓ 构建文件包含新的错误消息"
else
    echo "  ⚠️  构建文件中未找到新消息，可能使用了旧代码"
    echo "  检查构建文件中的错误消息："
    grep -r "无法连接到后端" dist/ | head -3 || echo "  未找到"
fi

# 5. 重启 Nginx
echo ""
echo "重启 Nginx..."
systemctl restart nginx

echo ""
echo "========================================"
echo "  更新完成！"
echo "========================================"
echo ""
echo "请清除浏览器缓存后访问：http://47.112.29.212"
echo ""

