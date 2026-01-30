#!/bin/bash
# 完整的后端服务修复脚本
# 在服务器上执行: bash deploy/fix-backend-complete.sh

set -e

echo "=========================================="
echo "开始修复后端服务（完整版）"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 1. 检查当前状态
echo "1. 检查后端服务状态..."
sudo systemctl status my-fullstack-app --no-pager -l | head -15 || echo "服务未运行"
echo ""

# 2. 检查端口监听
echo "2. 检查端口8000监听状态..."
if netstat -tlnp | grep :8000 > /dev/null; then
    echo "✓ 端口8000正在监听"
    netstat -tlnp | grep :8000
else
    echo "✗ 端口8000未监听"
fi
echo ""

# 3. 查看后端日志
echo "3. 查看后端服务最近日志（最后30行）..."
sudo journalctl -u my-fullstack-app -n 30 --no-pager
echo ""

# 4. 测试后端API（本地）
echo "4. 测试后端API（本地8000端口）..."
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ 后端API正常响应"
    curl -s http://127.0.0.1:8000/api/health
else
    echo "✗ 后端API无响应"
fi
echo ""

# 5. 更新systemd服务文件（修复ALLOWED_ORIGINS）
echo "5. 更新systemd服务文件..."
SERVICE_FILE="/etc/systemd/system/my-fullstack-app.service"
if grep -q "YOUR_SERVER_IP" "$SERVICE_FILE"; then
    echo "发现占位符，正在更新..."
    sudo sed -i 's|ALLOWED_ORIGINS=http://YOUR_SERVER_IP,https://YOUR_SERVER_IP|ALLOWED_ORIGINS=http://47.112.29.212,https://linchuan.tech,http://linchuan.tech|g' "$SERVICE_FILE"
    echo "✓ 已更新ALLOWED_ORIGINS配置"
else
    echo "✓ ALLOWED_ORIGINS配置已正确"
fi
echo ""

# 6. 重新加载systemd配置
echo "6. 重新加载systemd配置..."
sudo systemctl daemon-reload
echo "✓ 配置已重新加载"
echo ""

# 7. 停止服务
echo "7. 停止后端服务..."
sudo systemctl stop my-fullstack-app
sleep 2
echo ""

# 8. 检查是否有残留进程
echo "8. 检查并清理残留进程..."
pkill -f "uvicorn main:app" || echo "无残留进程"
sleep 1
echo ""

# 9. 重启后端服务
echo "9. 启动后端服务..."
sudo systemctl start my-fullstack-app
sleep 5
echo ""

# 10. 检查服务状态
echo "10. 检查服务状态..."
if sudo systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务运行正常"
    sudo systemctl status my-fullstack-app --no-pager -l | head -15
else
    echo "✗ 服务启动失败"
    sudo systemctl status my-fullstack-app --no-pager -l | head -30
fi
echo ""

# 11. 再次测试API
echo "11. 测试后端API..."
sleep 2
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ 后端API正常"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "✗ 后端API仍无响应，查看详细日志："
    sudo journalctl -u my-fullstack-app -n 50 --no-pager
fi
echo ""

# 12. 检查Nginx配置
echo "12. 检查Nginx配置..."
if sudo nginx -t 2>&1 | grep -q "successful"; then
    echo "✓ Nginx配置正确"
else
    echo "✗ Nginx配置有误"
    sudo nginx -t
fi
echo ""

# 13. 重启Nginx
echo "13. 重启Nginx..."
sudo systemctl restart nginx
sleep 2
echo ""

# 14. 测试通过Nginx访问API
echo "14. 测试通过Nginx访问API..."
if curl -s http://127.0.0.1/api/health > /dev/null; then
    echo "✓ Nginx代理正常"
    curl -s http://127.0.0.1/api/health
    echo ""
else
    echo "✗ Nginx代理失败，检查Nginx日志："
    sudo tail -20 /var/log/nginx/error.log
fi
echo ""

# 15. 检查Nginx错误日志
echo "15. 检查Nginx最近错误日志..."
if [ -f /var/log/nginx/error.log ]; then
    echo "最近10条错误日志："
    sudo tail -10 /var/log/nginx/error.log || echo "无错误日志"
else
    echo "错误日志文件不存在"
fi
echo ""

echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  HTTP:  http://47.112.29.212"
echo "  HTTPS: https://linchuan.tech"
echo ""
echo "如果仍有问题，请检查："
echo "  1. 后端日志: sudo journalctl -u my-fullstack-app -f"
echo "  2. Nginx日志: sudo tail -f /var/log/nginx/error.log"
echo "  3. 防火墙: sudo ufw status"
echo ""

