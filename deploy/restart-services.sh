#!/bin/bash
# 重启应用服务脚本
# 使用方法: sudo bash restart-services.sh

echo "========================================"
echo "  重启应用服务"
echo "========================================"
echo ""

# 1. 重启后端服务
echo "[1/2] 重启后端服务..."
systemctl restart my-fullstack-app
sleep 2

if systemctl is-active --quiet my-fullstack-app; then
    echo "  ✓ 后端服务重启成功"
    systemctl status my-fullstack-app --no-pager -l | head -5
else
    echo "  ✗ 后端服务重启失败"
    systemctl status my-fullstack-app --no-pager -l | head -10
fi

echo ""

# 2. 重启 Nginx
echo "[2/2] 重启 Nginx..."
nginx -t && systemctl restart nginx
sleep 1

if systemctl is-active --quiet nginx; then
    echo "  ✓ Nginx 重启成功"
    systemctl status nginx --no-pager -l | head -5
else
    echo "  ✗ Nginx 重启失败"
    systemctl status nginx --no-pager -l | head -10
fi

echo ""
echo "========================================"
echo "  服务重启完成"
echo "========================================"
echo ""
echo "测试 API:"
curl -s http://localhost:8000/api/data && echo "" || echo "后端 API 测试失败"
curl -s http://localhost/api/data && echo "" || echo "Nginx 代理测试失败"
echo ""

