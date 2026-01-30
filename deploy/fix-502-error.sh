#!/bin/bash
# 修复 502 错误的完整脚本
# 在服务器上执行: bash deploy/fix-502-error.sh

set -e

echo "=========================================="
echo "诊断和修复 502 错误"
echo "=========================================="
echo ""

# 1. 检查后端服务状态
echo ">>> 1. 检查后端服务状态..."
systemctl status my-fullstack-app --no-pager -l | head -20
echo ""

# 2. 检查端口监听
echo ">>> 2. 检查端口 8000 是否监听..."
if netstat -tlnp | grep :8000 > /dev/null 2>&1; then
    echo "✓ 端口 8000 正在监听"
    netstat -tlnp | grep :8000
elif ss -tlnp | grep :8000 > /dev/null 2>&1; then
    echo "✓ 端口 8000 正在监听"
    ss -tlnp | grep :8000
else
    echo "✗ 端口 8000 未监听"
fi
echo ""

# 3. 测试后端 API（本地）
echo ">>> 3. 测试后端 API（本地 8000 端口）..."
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ 后端 API 正常响应"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "✗ 后端 API 无响应"
fi
echo ""

# 4. 查看后端服务日志
echo ">>> 4. 查看后端服务最近日志（最后 30 行）..."
journalctl -u my-fullstack-app -n 30 --no-pager
echo ""

# 5. 检查 Nginx 配置
echo ">>> 5. 检查 Nginx 配置..."
if nginx -t 2>&1 | grep -q "successful"; then
    echo "✓ Nginx 配置正确"
else
    echo "✗ Nginx 配置有误"
    nginx -t
fi
echo ""

# 6. 查看 Nginx 错误日志
echo ">>> 6. 查看 Nginx 最近错误日志..."
if [ -f /var/log/nginx/error.log ]; then
    echo "最近 20 条错误日志:"
    tail -n 20 /var/log/nginx/error.log
else
    echo "错误日志文件不存在"
fi
echo ""

# 7. 检查 systemd 服务配置
echo ">>> 7. 检查 systemd 服务配置..."
SERVICE_FILE="/etc/systemd/system/my-fullstack-app.service"
if [ -f "$SERVICE_FILE" ]; then
    echo "服务文件存在，检查关键配置:"
    grep -E "ExecStart|WorkingDirectory|Environment" "$SERVICE_FILE" || echo "未找到关键配置"
else
    echo "✗ 服务文件不存在: $SERVICE_FILE"
fi
echo ""

# 8. 尝试重启后端服务
echo ">>> 8. 重启后端服务..."
systemctl daemon-reload
systemctl stop my-fullstack-app
sleep 2

# 检查是否有残留进程
pkill -f "uvicorn main:app" || echo "无残留进程"
sleep 1

systemctl start my-fullstack-app
sleep 5

# 检查服务状态
if systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务启动成功"
else
    echo "✗ 服务启动失败"
    echo "详细日志:"
    journalctl -u my-fullstack-app -n 50 --no-pager
fi
echo ""

# 9. 再次测试 API
echo ">>> 9. 再次测试后端 API..."
sleep 2
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ 后端 API 现在正常"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "✗ 后端 API 仍然无响应"
    echo "请检查以下内容:"
    echo "  1. Python 虚拟环境是否正确: cd /var/www/my-fullstack-app/backend && source ../venv/bin/activate && python -c 'from main import app; print(\"OK\")'"
    echo "  2. 数据库连接是否正常"
    echo "  3. 查看完整日志: journalctl -u my-fullstack-app -f"
fi
echo ""

# 10. 重启 Nginx
echo ">>> 10. 重启 Nginx..."
systemctl restart nginx
sleep 2

if systemctl is-active --quiet nginx; then
    echo "✓ Nginx 运行正常"
else
    echo "✗ Nginx 启动失败"
    systemctl status nginx --no-pager -l | head -20
fi
echo ""

# 11. 测试通过 Nginx 访问
echo ">>> 11. 测试通过 Nginx 访问 API..."
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/api/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ Nginx 代理正常 (HTTP $HTTP_CODE)"
    curl -s http://127.0.0.1/api/health
    echo ""
else
    echo "✗ Nginx 代理失败 (HTTP $HTTP_CODE)"
    echo "检查 Nginx 错误日志: tail -n 30 /var/log/nginx/error.log"
fi
echo ""

echo "=========================================="
echo "诊断完成"
echo "=========================================="
echo ""
echo "如果问题仍然存在，请执行以下命令获取更多信息:"
echo "  journalctl -u my-fullstack-app -f  # 实时查看后端日志"
echo "  tail -f /var/log/nginx/error.log  # 实时查看 Nginx 错误日志"
echo "  systemctl status my-fullstack-app -l  # 查看服务详细状态"
echo ""

