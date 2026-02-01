#!/bin/bash
# 立即恢复服务 - 最简单版本
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/立即恢复服务.sh

set -e

echo "=========================================="
echo "立即恢复服务"
echo "=========================================="
echo ""

# 1. 确保后端服务运行
echo ">>> 1. 检查后端服务..."
sudo systemctl restart my-fullstack-app
sleep 3

if curl -s http://127.0.0.1:8000/api/health > /dev/null 2>&1; then
    echo "✓ 后端服务正常"
else
    echo "✗ 后端服务异常，查看日志:"
    sudo journalctl -u my-fullstack-app -n 20 --no-pager
    echo "继续恢复 Nginx..."
fi
echo ""

# 2. 应用最简单的配置
echo ">>> 2. 应用最简单的 Nginx 配置..."
NGINX_CONF="/etc/nginx/conf.d/my-fullstack-app.conf"

# 备份当前配置
if [ -f "$NGINX_CONF" ]; then
    sudo cp "$NGINX_CONF" "${NGINX_CONF}.broken.$(date +%Y%m%d_%H%M%S)"
fi

# 检测使用 HTTPS 还是 HTTP
if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ]; then
    echo "使用 HTTPS 配置"
    sudo cp /var/www/my-fullstack-app/scripts/deploy/最简单恢复配置-https.conf "$NGINX_CONF"
else
    echo "使用 HTTP 配置"
    sudo cp /var/www/my-fullstack-app/scripts/deploy/最简单恢复配置.conf "$NGINX_CONF"
fi

echo "✓ 配置已应用"
echo ""

# 3. 测试配置
echo ">>> 3. 测试配置..."
if sudo nginx -t; then
    echo "✓ 配置测试通过"
else
    echo "✗ 配置测试失败，使用最基础配置..."
    sudo tee "$NGINX_CONF" > /dev/null << 'BASIC_CONF'
upstream backend {
    server 127.0.0.1:8000;
}
server {
    listen 80;
    server_name _;
    root /var/www/my-fullstack-app/frontend/dist;
    index index.html;
    location /data/ { proxy_pass http://backend; }
    location /api/ { proxy_pass http://backend; }
    location / { try_files $uri $uri/ /index.html; }
}
BASIC_CONF
    sudo nginx -t
fi
echo ""

# 4. 重启 Nginx
echo ">>> 4. 重启 Nginx..."
sudo systemctl restart nginx
sleep 3

if systemctl is-active --quiet nginx; then
    echo "✓ Nginx 已启动"
else
    echo "✗ Nginx 启动失败，查看日志:"
    sudo journalctl -u nginx -n 20 --no-pager
    exit 1
fi
echo ""

# 5. 验证
echo ">>> 5. 验证服务..."
sleep 2

BACKEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
if [ "$BACKEND_CODE" = "200" ]; then
    echo "✓ 后端正常 (HTTP $BACKEND_CODE)"
else
    echo "✗ 后端异常 (HTTP $BACKEND_CODE)"
fi

NGINX_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/api/health 2>/dev/null || echo "000")
if [ "$NGINX_CODE" = "200" ]; then
    echo "✓ Nginx 代理正常 (HTTP $NGINX_CODE)"
else
    echo "✗ Nginx 代理异常 (HTTP $NGINX_CODE)"
fi

echo ""
echo "=========================================="
echo "恢复完成！"
echo "=========================================="
echo ""
echo "如果仍然无法访问，请检查："
echo "1. 防火墙: sudo firewall-cmd --list-all"
echo "2. 后端日志: sudo journalctl -u my-fullstack-app -n 50 --no-pager"
echo "3. Nginx 日志: sudo tail -n 50 /var/log/nginx/error.log"
echo ""

