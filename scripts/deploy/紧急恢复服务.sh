#!/bin/bash
# 紧急恢复服务
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/紧急恢复服务.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"
NGINX_CONF="/etc/nginx/conf.d/my-fullstack-app.conf"

echo "=========================================="
echo "紧急恢复服务"
echo "=========================================="
echo ""

cd "$DEPLOY_PATH"

# 1. 检查后端服务状态
echo ">>> 1. 检查后端服务状态..."
if systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 后端服务正在运行"
else
    echo "✗ 后端服务未运行，正在启动..."
    sudo systemctl start my-fullstack-app
    sleep 3
fi

# 检查后端是否真的在运行
if curl -s http://127.0.0.1:8000/api/health > /dev/null 2>&1; then
    echo "✓ 后端 API 可访问"
else
    echo "✗ 后端 API 无法访问，查看日志..."
    sudo journalctl -u my-fullstack-app -n 20 --no-pager
    echo ""
    echo "尝试重启后端服务..."
    sudo systemctl restart my-fullstack-app
    sleep 5
fi
echo ""

# 2. 检查 Nginx 配置
echo ">>> 2. 检查 Nginx 配置..."
if sudo nginx -t 2>&1 | grep -q "test is successful"; then
    echo "✓ Nginx 配置正确"
else
    echo "✗ Nginx 配置有错误，尝试恢复备份..."
    
    # 查找最新的备份
    BACKUP=$(ls -t ${NGINX_CONF}.backup.* 2>/dev/null | head -1)
    if [ -n "$BACKUP" ]; then
        echo "恢复备份: $BACKUP"
        sudo cp "$BACKUP" "$NGINX_CONF"
        echo "✓ 已恢复备份配置"
    else
        echo "⚠ 没有找到备份，使用默认配置..."
        # 创建一个最简单的可用配置
        sudo tee "$NGINX_CONF" > /dev/null << 'SIMPLE_CONF'
upstream backend {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name _;

    root /var/www/my-fullstack-app/frontend/dist;
    index index.html;

    location /data/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
SIMPLE_CONF
        echo "✓ 已创建简单配置"
    fi
    
    # 再次测试
    if sudo nginx -t; then
        echo "✓ 配置测试通过"
    else
        echo "✗ 配置仍然有问题，查看错误："
        sudo nginx -t 2>&1
        exit 1
    fi
fi
echo ""

# 3. 重启 Nginx
echo ">>> 3. 重启 Nginx..."
sudo systemctl reload nginx
sleep 2

if systemctl is-active --quiet nginx; then
    echo "✓ Nginx 运行正常"
else
    echo "✗ Nginx 未运行，尝试启动..."
    sudo systemctl start nginx
    sleep 2
fi
echo ""

# 4. 验证服务
echo ">>> 4. 验证服务..."
sleep 2

# 测试后端
BACKEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
if [ "$BACKEND_CODE" = "200" ]; then
    echo "✓ 后端 API 正常 (HTTP $BACKEND_CODE)"
else
    echo "✗ 后端 API 异常 (HTTP $BACKEND_CODE)"
    echo "查看后端日志:"
    sudo journalctl -u my-fullstack-app -n 30 --no-pager
fi

# 测试 Nginx
NGINX_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/api/health 2>/dev/null || echo "000")
if [ "$NGINX_CODE" = "200" ]; then
    echo "✓ Nginx 代理正常 (HTTP $NGINX_CODE)"
else
    echo "✗ Nginx 代理异常 (HTTP $NGINX_CODE)"
    echo "查看 Nginx 错误日志:"
    sudo tail -n 20 /var/log/nginx/error.log 2>/dev/null || echo "无法读取日志"
fi

echo ""
echo "=========================================="
echo "恢复完成！"
echo "=========================================="
echo ""
echo "如果服务仍然无法访问，请检查："
echo "1. 后端服务: sudo systemctl status my-fullstack-app"
echo "2. Nginx 服务: sudo systemctl status nginx"
echo "3. 后端日志: sudo journalctl -u my-fullstack-app -n 50 --no-pager"
echo "4. Nginx 日志: sudo tail -n 50 /var/log/nginx/error.log"
echo ""

