#!/bin/bash
# 修复后端服务问题的完整脚本
# 在服务器上执行

set -e

echo "=========================================="
echo "开始修复后端服务"
echo "=========================================="
echo ""

# 1. 检查后端服务状态
echo "1. 检查后端服务状态..."
sudo systemctl status my-fullstack-app --no-pager -l | head -15
echo ""

# 2. 检查端口监听
echo "2. 检查端口8000是否监听..."
netstat -tlnp | grep :8000 || echo "警告: 端口8000未监听"
echo ""

# 3. 检查后端日志
echo "3. 查看后端服务最近日志..."
sudo journalctl -u my-fullstack-app -n 30 --no-pager
echo ""

# 4. 测试后端API（本地）
echo "4. 测试后端API（本地）..."
curl -s http://127.0.0.1:8000/api/health || echo "错误: 无法连接到后端"
echo ""

# 5. 检查systemd服务文件
echo "5. 检查systemd服务配置..."
cat /etc/systemd/system/my-fullstack-app.service | grep -E "ALLOWED_ORIGINS|ExecStart"
echo ""

# 6. 更新systemd服务文件（修复ALLOWED_ORIGINS）
echo "6. 更新systemd服务文件..."
sudo sed -i 's|ALLOWED_ORIGINS=http://YOUR_SERVER_IP,https://YOUR_SERVER_IP|ALLOWED_ORIGINS=http://47.112.29.212,https://linchuan.tech,http://linchuan.tech|g' /etc/systemd/system/my-fullstack-app.service
echo "已更新ALLOWED_ORIGINS配置"
echo ""

# 7. 重新加载systemd配置
echo "7. 重新加载systemd配置..."
sudo systemctl daemon-reload
echo ""

# 8. 重启后端服务
echo "8. 重启后端服务..."
sudo systemctl restart my-fullstack-app
sleep 3
echo ""

# 9. 再次检查服务状态
echo "9. 检查服务状态..."
sudo systemctl status my-fullstack-app --no-pager -l | head -15
echo ""

# 10. 测试API
echo "10. 测试后端API..."
curl -s http://127.0.0.1:8000/api/health && echo "" || echo "错误: API无响应"
echo ""

# 11. 检查Nginx配置
echo "11. 检查Nginx配置..."
sudo nginx -t
echo ""

# 12. 重启Nginx
echo "12. 重启Nginx..."
sudo systemctl restart nginx
echo ""

# 13. 测试通过Nginx访问API
echo "13. 测试通过Nginx访问API..."
curl -s http://127.0.0.1/api/health && echo "" || echo "错误: Nginx代理失败"
echo ""

echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  HTTP:  http://47.112.29.212"
echo "  HTTPS: https://linchuan.tech"
echo ""

