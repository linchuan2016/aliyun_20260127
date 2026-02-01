#!/bin/bash
# 一键修复图片问题（干净版本，移除所有 attu/milvus 配置）
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/一键修复图片问题.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"
NGINX_CONF="/etc/nginx/conf.d/my-fullstack-app.conf"

echo "=========================================="
echo "一键修复图片问题"
echo "=========================================="
echo ""

cd "$DEPLOY_PATH"

# 1. 修复图片文件权限
echo ">>> 1. 修复图片文件权限..."
SERVICE_USER=$(ps aux | grep '[u]vicorn' | head -1 | awk '{print $1}' || echo "www-data")
if [ -z "$SERVICE_USER" ] || [ "$SERVICE_USER" = "root" ]; then
    SERVICE_USER=$(systemctl show -p User my-fullstack-app 2>/dev/null | cut -d= -f2 || echo "www-data")
fi

sudo chown -R "$SERVICE_USER:$SERVICE_USER" data/ 2>/dev/null || sudo chown -R "$(whoami):$(whoami)" data/
sudo chmod -R 755 data/
echo "✓ 权限已修复"
echo ""

# 2. 备份当前配置
echo ">>> 2. 备份当前配置..."
if [ -f "$NGINX_CONF" ]; then
    sudo cp "$NGINX_CONF" "${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ 配置已备份"
fi
echo ""

# 3. 应用干净的 Nginx 配置
echo ">>> 3. 应用干净的 Nginx 配置..."
if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ]; then
    echo "使用 HTTPS 配置"
    sudo cp scripts/deploy/nginx-ssl.conf "$NGINX_CONF"
else
    echo "使用 HTTP 配置"
    sudo cp scripts/deploy/nginx.conf "$NGINX_CONF"
fi
echo "✓ 配置已应用"
echo ""

# 4. 测试 Nginx 配置
echo ">>> 4. 测试 Nginx 配置..."
if sudo nginx -t; then
    echo "✓ Nginx 配置测试通过"
else
    echo "✗ Nginx 配置测试失败"
    echo "错误信息："
    sudo nginx -t 2>&1
    exit 1
fi
echo ""

# 5. 重启 Nginx
echo ">>> 5. 重启 Nginx..."
sudo systemctl reload nginx
sleep 2
echo "✓ Nginx 已重启"
echo ""

# 6. 验证 /data/ location 配置
echo ">>> 6. 验证配置..."
if grep -A 5 "location /data/" "$NGINX_CONF" | grep -q "proxy_pass.*backend"; then
    echo "✓ /data/ location 配置正确"
    echo "配置内容："
    grep -A 5 "location /data/" "$NGINX_CONF"
else
    echo "✗ /data/ location 配置错误"
    exit 1
fi
echo ""

# 7. 测试图片访问
echo ">>> 7. 测试图片访问..."
sleep 2

echo "测试后端直接访问:"
BACKEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/data/book-covers/s3259913.jpg 2>/dev/null || echo "000")
if [ "$BACKEND_CODE" = "200" ]; then
    echo "✓ 后端直接访问正常 (HTTP $BACKEND_CODE)"
else
    echo "✗ 后端直接访问失败 (HTTP $BACKEND_CODE)"
fi

echo ""
echo "测试通过 Nginx 访问:"
if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ]; then
    NGINX_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k https://127.0.0.1/data/book-covers/s3259913.jpg 2>/dev/null || echo "000")
    NGINX_URL="https://linchuan.tech/data/book-covers/s3259913.jpg"
else
    NGINX_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/data/book-covers/s3259913.jpg 2>/dev/null || echo "000")
    NGINX_URL="http://127.0.0.1/data/book-covers/s3259913.jpg"
fi

if [ "$NGINX_CODE" = "200" ]; then
    echo "✓ Nginx 访问正常 (HTTP $NGINX_CODE)"
    echo "  可以访问: $NGINX_URL"
else
    echo "✗ Nginx 访问失败 (HTTP $NGINX_CODE)"
    echo "  请检查 Nginx 错误日志: sudo tail -n 20 /var/log/nginx/my-fullstack-app-error.log"
fi

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "如果图片仍然无法访问，请检查："
echo "1. 后端服务是否运行: sudo systemctl status my-fullstack-app"
echo "2. Nginx 错误日志: sudo tail -n 50 /var/log/nginx/my-fullstack-app-error.log"
echo "3. 后端日志: sudo journalctl -u my-fullstack-app -n 50 --no-pager"
echo ""

