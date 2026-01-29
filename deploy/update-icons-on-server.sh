#!/bin/bash
# 更新服务器上的图标路径脚本
# 在服务器上执行此脚本来更新数据库中的图标URL

set -e

echo "=========================================="
echo "更新服务器图标路径"
echo "=========================================="

# 项目路径
PROJECT_DIR="/var/www/my-fullstack-app"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"

# 1. 检查图标文件是否存在
echo ""
echo "1. 检查图标文件..."
if [ -d "$FRONTEND_DIR/dist/icons" ]; then
    echo "✓ 图标目录存在"
    ls -la "$FRONTEND_DIR/dist/icons/" | head -10
else
    echo "⚠ 警告: 图标目录不存在，需要先构建前端"
fi

# 2. 激活虚拟环境并运行更新脚本
echo ""
echo "2. 更新数据库中的图标路径..."
cd "$BACKEND_DIR"

# 检查虚拟环境
if [ -d "venv" ]; then
    source venv/bin/activate
    echo "✓ 虚拟环境已激活"
elif [ -d "../venv" ]; then
    source ../venv/bin/activate
    echo "✓ 虚拟环境已激活"
else
    echo "⚠ 警告: 未找到虚拟环境，使用系统Python"
fi

# 运行更新脚本
python update_icons.py

# 3. 重启后端服务
echo ""
echo "3. 重启后端服务..."
sudo systemctl restart my-fullstack-app
echo "✓ 后端服务已重启"

# 4. 检查服务状态
echo ""
echo "4. 检查服务状态..."
sleep 2
sudo systemctl status my-fullstack-app --no-pager | head -10

echo ""
echo "=========================================="
echo "更新完成！"
echo "=========================================="
echo ""
echo "如果前端代码有更新，请执行："
echo "  cd $FRONTEND_DIR"
echo "  npm run build"
echo "  sudo systemctl reload nginx"
echo ""

