#!/bin/bash
# 部署验证检查脚本
# 使用方法: sudo bash check-deployment.sh

echo "========================================"
echo "  部署验证检查"
echo "========================================"
echo ""

SERVER_IP="47.112.29.212"  # 修改为你的服务器 IP
ALL_CHECKS_PASSED=true

# 1. 检查后端服务
echo "[1/8] 检查后端服务..."
if systemctl is-active --quiet my-fullstack-app 2>/dev/null; then
    echo "  ✓ 后端服务运行中"
    STATUS=$(systemctl status my-fullstack-app --no-pager | grep "Active:" | awk '{print $2, $3}')
    echo "    状态: $STATUS"
else
    echo "  ✗ 后端服务未运行"
    ALL_CHECKS_PASSED=false
fi

# 2. 检查后端端口
echo "[2/8] 检查后端端口..."
if netstat -tlnp 2>/dev/null | grep -q ":8000" || ss -tlnp 2>/dev/null | grep -q ":8000"; then
    echo "  ✓ 端口 8000 正在监听"
else
    echo "  ✗ 端口 8000 未监听"
    ALL_CHECKS_PASSED=false
fi

# 3. 测试后端 API
echo "[3/8] 测试后端 API..."
API_RESPONSE=$(curl -s http://localhost:8000/api/data 2>/dev/null)
if echo "$API_RESPONSE" | grep -q "Hello World"; then
    echo "  ✓ 后端 API 正常"
    echo "    响应: $API_RESPONSE"
else
    echo "  ✗ 后端 API 异常"
    echo "    响应: $API_RESPONSE"
    ALL_CHECKS_PASSED=false
fi

# 4. 检查 Nginx
echo "[4/8] 检查 Nginx..."
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "  ✓ Nginx 运行中"
    STATUS=$(systemctl status nginx --no-pager | grep "Active:" | awk '{print $2, $3}')
    echo "    状态: $STATUS"
else
    echo "  ✗ Nginx 未运行"
    ALL_CHECKS_PASSED=false
fi

# 5. 检查 Nginx 端口
echo "[5/8] 检查 Nginx 端口..."
if netstat -tlnp 2>/dev/null | grep -q ":80" || ss -tlnp 2>/dev/null | grep -q ":80"; then
    echo "  ✓ 端口 80 正在监听"
else
    echo "  ✗ 端口 80 未监听"
    ALL_CHECKS_PASSED=false
fi

# 6. 检查前端文件
echo "[6/8] 检查前端文件..."
if [ -f "/var/www/my-fullstack-app/frontend/dist/index.html" ]; then
    echo "  ✓ 前端文件存在"
    FILE_SIZE=$(du -sh /var/www/my-fullstack-app/frontend/dist 2>/dev/null | awk '{print $1}')
    echo "    大小: $FILE_SIZE"
else
    echo "  ✗ 前端文件不存在"
    ALL_CHECKS_PASSED=false
fi

# 7. 检查防火墙
echo "[7/8] 检查防火墙..."
if systemctl is-active --quiet firewalld 2>/dev/null; then
    if firewall-cmd --list-all 2>/dev/null | grep -q "http"; then
        echo "  ✓ 防火墙已配置 HTTP"
    else
        echo "  ⚠️  防火墙未配置 HTTP"
    fi
else
    echo "  ⚠️  firewalld 未运行（请检查阿里云安全组）"
fi

# 8. 测试外部访问
echo "[8/8] 测试外部访问..."
EXTERNAL_RESPONSE=$(curl -s --max-time 5 "http://$SERVER_IP/api/data" 2>/dev/null)
if echo "$EXTERNAL_RESPONSE" | grep -q "Hello World"; then
    echo "  ✓ 外部访问正常"
    echo "    响应: $EXTERNAL_RESPONSE"
else
    echo "  ⚠️  外部访问异常（可能是防火墙或安全组问题）"
    echo "    响应: $EXTERNAL_RESPONSE"
fi

echo ""
echo "========================================"
if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo "  ✓ 所有核心检查通过！"
else
    echo "  ⚠️  部分检查未通过，请查看上方详细信息"
fi
echo "========================================"
echo ""
echo "访问地址: http://$SERVER_IP"
echo ""
echo "常用命令："
echo "  查看后端日志: sudo journalctl -u my-fullstack-app -f"
echo "  查看 Nginx 日志: sudo tail -f /var/log/nginx/my-fullstack-app-error.log"
echo "  重启服务: sudo systemctl restart my-fullstack-app && sudo systemctl restart nginx"
echo ""

