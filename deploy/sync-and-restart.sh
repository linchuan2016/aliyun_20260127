#!/bin/bash
# 同步代码到服务器并重启服务
# 使用方法: sudo bash sync-and-restart.sh

set -e

echo "========================================"
echo "  同步代码并重启服务"
echo "========================================"
echo ""

APP_DIR="/var/www/my-fullstack-app"
SERVER_IP="47.112.29.212"

# 1. 拉取最新代码
echo "[1/5] 拉取最新代码..."
cd $APP_DIR

# 尝试从 GitHub 拉取
if git pull 2>/dev/null; then
    echo "  ✓ 从 GitHub 拉取成功"
else
    echo "  ⚠️  GitHub 连接失败，跳过拉取"
    echo "  提示：如果代码有更新，请手动修改文件或使用其他方式同步"
fi

# 2. 修复前端文件（确保使用相对路径）
echo "[2/5] 检查前端代码..."
if grep -q "http://127.0.0.1:8000" $APP_DIR/frontend/src/App.vue 2>/dev/null; then
    echo "  修复前端 API 地址..."
    sed -i "s|http://127.0.0.1:8000/api/data|/api/data|g" $APP_DIR/frontend/src/App.vue
    sed -i "s|'http://127.0.0.1:8000/api/data'|'/api/data'|g" $APP_DIR/frontend/src/App.vue
    echo "  ✓ 前端代码已修复"
else
    echo "  ✓ 前端代码正常"
fi

# 3. 重新构建前端
echo "[3/5] 重新构建前端..."
cd $APP_DIR/frontend
npm run build
echo "  ✓ 前端构建完成"

# 4. 重启后端服务
echo "[4/5] 重启后端服务..."
systemctl restart my-fullstack-app
sleep 2
if systemctl is-active --quiet my-fullstack-app; then
    echo "  ✓ 后端服务重启成功"
else
    echo "  ✗ 后端服务重启失败"
    systemctl status my-fullstack-app --no-pager -l | head -10
fi

# 5. 重启 Nginx
echo "[5/5] 重启 Nginx..."
nginx -t && systemctl restart nginx
if systemctl is-active --quiet nginx; then
    echo "  ✓ Nginx 重启成功"
else
    echo "  ✗ Nginx 重启失败"
    systemctl status nginx --no-pager -l | head -10
fi

echo ""
echo "========================================"
echo "  完成！"
echo "========================================"
echo ""
echo "服务状态："
systemctl status my-fullstack-app --no-pager -l | head -3
systemctl status nginx --no-pager -l | head -3
echo ""
echo "访问地址: http://$SERVER_IP"
echo ""
echo "测试 API:"
curl -s http://localhost:8000/api/data || echo "后端 API 测试失败"
curl -s http://localhost/api/data || echo "Nginx 代理测试失败"
echo ""

