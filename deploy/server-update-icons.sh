#!/bin/bash
# 服务器端更新图标路径脚本
# 在服务器上执行此脚本

set -e

echo "=========================================="
echo "更新服务器图标路径"
echo "=========================================="

# 项目路径
PROJECT_DIR="/var/www/my-fullstack-app"
BACKEND_DIR="$PROJECT_DIR/backend"
VENV_DIR="$PROJECT_DIR/venv"

# 1. 进入项目目录
cd "$PROJECT_DIR"

# 2. 拉取最新代码
echo ""
echo "1. 拉取最新代码..."
git pull gitee main
echo "✓ 代码已更新"

# 3. 检查 update_icons.py 文件是否存在
echo ""
echo "2. 检查更新脚本..."
if [ ! -f "$BACKEND_DIR/update_icons.py" ]; then
    echo "✗ 错误: update_icons.py 文件不存在"
    echo "请确认代码已成功拉取"
    exit 1
fi
echo "✓ 更新脚本存在"

# 4. 检查虚拟环境
echo ""
echo "3. 检查虚拟环境..."
if [ ! -d "$VENV_DIR" ]; then
    echo "✗ 错误: 虚拟环境不存在于 $VENV_DIR"
    echo "请先创建虚拟环境"
    exit 1
fi
echo "✓ 虚拟环境存在"

# 5. 激活虚拟环境并运行更新脚本
echo ""
echo "4. 更新数据库中的图标路径..."
cd "$BACKEND_DIR"
source "$VENV_DIR/bin/activate"
python update_icons.py
deactivate

# 6. 重启后端服务
echo ""
echo "5. 重启后端服务..."
sudo systemctl restart my-fullstack-app
echo "✓ 后端服务已重启"

# 7. 检查服务状态
echo ""
echo "6. 检查服务状态..."
sleep 2
sudo systemctl status my-fullstack-app --no-pager | head -15

echo ""
echo "=========================================="
echo "更新完成！"
echo "=========================================="
echo ""
echo "如果前端代码有更新，请执行："
echo "  cd $PROJECT_DIR/frontend"
echo "  npm run build"
echo "  sudo systemctl reload nginx"
echo ""

