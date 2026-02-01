#!/bin/bash
# 全面诊断和修复服务
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/全面诊断和修复.sh

set -e

echo "=========================================="
echo "全面诊断和修复服务"
echo "=========================================="
echo ""

# 1. 检查后端服务
echo ">>> 1. 检查后端服务..."
if systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 后端服务正在运行"
    systemctl status my-fullstack-app --no-pager -l | head -10
else
    echo "✗ 后端服务未运行"
    echo "尝试启动..."
    sudo systemctl start my-fullstack-app
    sleep 5
    if systemctl is-active --quiet my-fullstack-app; then
        echo "✓ 后端服务已启动"
    else
        echo "✗ 后端服务启动失败，查看日志:"
        sudo journalctl -u my-fullstack-app -n 30 --no-pager
    fi
fi

# 测试后端端口
echo ""
echo "测试后端端口 8000:"
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "✓ 端口 8000 正在监听"
    netstat -tlnp 2>/dev/null | grep :8000 || ss -tlnp 2>/dev/null | grep :8000
else
    echo "✗ 端口 8000 未监听"
fi

# 测试后端 API
if curl -s http://127.0.0.1:8000/api/health > /dev/null 2>&1; then
    echo "✓ 后端 API 可访问"
    curl -s http://127.0.0.1:8000/api/health
else
    echo "✗ 后端 API 无法访问"
fi
echo ""

# 2. 检查 Nginx 服务
echo ">>> 2. 检查 Nginx 服务..."
if systemctl is-active --quiet nginx; then
    echo "✓ Nginx 正在运行"
    systemctl status nginx --no-pager -l | head -10
else
    echo "✗ Nginx 未运行"
    echo "查看错误:"
    sudo journalctl -u nginx -n 30 --no-pager
fi

# 检查 Nginx 端口
echo ""
echo "测试 Nginx 端口:"
if netstat -tlnp 2>/dev/null | grep :80 > /dev/null || ss -tlnp 2>/dev/null | grep :80 > /dev/null; then
    echo "✓ 端口 80 正在监听"
    netstat -tlnp 2>/dev/null | grep :80 || ss -tlnp 2>/dev/null | grep :80
else
    echo "✗ 端口 80 未监听"
fi

if netstat -tlnp 2>/dev/null | grep :443 > /dev/null || ss -tlnp 2>/dev/null | grep :443 > /dev/null; then
    echo "✓ 端口 443 正在监听"
    netstat -tlnp 2>/dev/null | grep :443 || ss -tlnp 2>/dev/null | grep :443
else
    echo "✗ 端口 443 未监听"
fi
echo ""

# 3. 检查 Nginx 配置
echo ">>> 3. 检查 Nginx 配置..."
NGINX_CONF="/etc/nginx/conf.d/my-fullstack-app.conf"

if [ -f "$NGINX_CONF" ]; then
    echo "配置文件存在: $NGINX_CONF"
    echo "配置文件内容（前20行）:"
    head -20 "$NGINX_CONF"
    echo ""
    
    # 测试配置
    if sudo nginx -t 2>&1 | grep -q "test is successful"; then
        echo "✓ Nginx 配置语法正确"
    else
        echo "✗ Nginx 配置有错误:"
        sudo nginx -t 2>&1
        echo ""
        echo "备份当前配置并创建简单配置..."
        sudo cp "$NGINX_CONF" "${NGINX_CONF}.broken.$(date +%Y%m%d_%H%M%S)"
    fi
else
    echo "✗ 配置文件不存在: $NGINX_CONF"
fi
echo ""

# 4. 检查 SSL 证书
echo ">>> 4. 检查 SSL 证书..."
if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ]; then
    echo "✓ SSL 证书存在"
    ls -lh /etc/nginx/ssl/linchuan.tech/
else
    echo "✗ SSL 证书不存在"
fi
echo ""

# 5. 检查防火墙
echo ">>> 5. 检查防火墙..."
if command -v firewall-cmd > /dev/null; then
    echo "防火墙状态:"
    sudo firewall-cmd --list-all 2>/dev/null || echo "无法获取防火墙状态"
else
    echo "未安装 firewalld"
fi
echo ""

# 6. 检查其他 Nginx 配置冲突
echo ">>> 6. 检查配置冲突..."
echo "所有 Nginx 配置文件:"
ls -la /etc/nginx/conf.d/ 2>/dev/null || echo "无法列出配置文件"
echo ""

# 7. 修复：创建最简单的可用配置
echo ">>> 7. 应用修复配置..."
if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ]; then
    echo "使用 HTTPS 配置"
    sudo tee "$NGINX_CONF" > /dev/null << 'HTTPS_EOF'
upstream backend {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name linchuan.tech www.linchuan.tech;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name linchuan.tech www.linchuan.tech;
    
    ssl_certificate /etc/nginx/ssl/linchuan.tech/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/linchuan.tech/privkey.pem;
    
    root /var/www/my-fullstack-app/frontend/dist;
    index index.html;
    
    location /data/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
HTTPS_EOF
else
    echo "使用 HTTP 配置"
    sudo tee "$NGINX_CONF" > /dev/null << 'HTTP_EOF'
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
    }
    
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
    }
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
HTTP_EOF
fi

# 测试配置
if sudo nginx -t; then
    echo "✓ 配置测试通过"
else
    echo "✗ 配置测试失败，使用最基础配置..."
    sudo tee "$NGINX_CONF" > /dev/null << 'BASIC_EOF'
upstream backend { server 127.0.0.1:8000; }
server {
    listen 80;
    server_name _;
    root /var/www/my-fullstack-app/frontend/dist;
    index index.html;
    location /data/ { proxy_pass http://backend; }
    location /api/ { proxy_pass http://backend; }
    location / { try_files $uri $uri/ /index.html; }
}
BASIC_EOF
    sudo nginx -t
fi
echo ""

# 8. 重启服务
echo ">>> 8. 重启服务..."
sudo systemctl restart my-fullstack-app
sleep 3
sudo systemctl restart nginx
sleep 3
echo "✓ 服务已重启"
echo ""

# 9. 最终验证
echo ">>> 9. 最终验证..."
sleep 2

echo "后端服务状态:"
systemctl is-active my-fullstack-app && echo "✓ 运行中" || echo "✗ 未运行"

echo "Nginx 服务状态:"
systemctl is-active nginx && echo "✓ 运行中" || echo "✗ 未运行"

echo ""
echo "测试后端 API:"
BACKEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
if [ "$BACKEND_CODE" = "200" ]; then
    echo "✓ 后端 API 正常 (HTTP $BACKEND_CODE)"
else
    echo "✗ 后端 API 异常 (HTTP $BACKEND_CODE)"
fi

echo ""
echo "测试 Nginx 代理:"
if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ]; then
    NGINX_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k https://127.0.0.1/api/health 2>/dev/null || echo "000")
else
    NGINX_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/api/health 2>/dev/null || echo "000")
fi

if [ "$NGINX_CODE" = "200" ]; then
    echo "✓ Nginx 代理正常 (HTTP $NGINX_CODE)"
else
    echo "✗ Nginx 代理异常 (HTTP $NGINX_CODE)"
    echo "查看 Nginx 错误日志:"
    sudo tail -n 20 /var/log/nginx/error.log 2>/dev/null || echo "无法读取日志"
fi

echo ""
echo "=========================================="
echo "诊断完成！"
echo "=========================================="
echo ""
echo "如果服务仍然无法访问，请检查："
echo "1. 阿里云安全组是否开放 80 和 443 端口"
echo "2. 服务器防火墙: sudo firewall-cmd --list-all"
echo "3. 后端日志: sudo journalctl -u my-fullstack-app -n 100 --no-pager"
echo "4. Nginx 日志: sudo tail -n 100 /var/log/nginx/error.log"
echo ""

