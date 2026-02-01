#!/bin/bash
# 深度修复 - 解决外部无法访问问题
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/深度修复-解决无法访问.sh

set -e

echo "=========================================="
echo "深度修复 - 解决外部无法访问问题"
echo "=========================================="
echo ""

# 1. 检查所有 Nginx 配置文件（可能有冲突）
echo ">>> 1. 检查所有 Nginx 配置文件..."
echo "conf.d 目录下的所有文件:"
ls -la /etc/nginx/conf.d/ 2>/dev/null || echo "无法访问 conf.d 目录"
echo ""

echo "sites-enabled 目录下的所有文件:"
ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "无法访问 sites-enabled 目录"
echo ""

# 检查是否有默认配置冲突
if [ -f "/etc/nginx/conf.d/default.conf" ]; then
    echo "⚠ 发现 default.conf，可能冲突，临时禁用..."
    sudo mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled 2>/dev/null || true
fi

# 2. 检查防火墙
echo ">>> 2. 检查防火墙..."
if command -v firewall-cmd > /dev/null; then
    echo "防火墙状态:"
    sudo firewall-cmd --state 2>/dev/null || echo "防火墙未运行"
    
    echo "开放的端口:"
    sudo firewall-cmd --list-ports 2>/dev/null || echo "无法获取端口列表"
    
    echo "开放的服务:"
    sudo firewall-cmd --list-services 2>/dev/null || echo "无法获取服务列表"
    
    # 确保 HTTP 和 HTTPS 开放
    echo "确保 HTTP 和 HTTPS 开放..."
    sudo firewall-cmd --permanent --add-service=http 2>/dev/null || true
    sudo firewall-cmd --permanent --add-service=https 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo "✓ 防火墙配置已更新"
else
    echo "未安装 firewalld，检查 iptables..."
    sudo iptables -L -n | grep -E "80|443" || echo "未找到相关规则"
fi
echo ""

# 3. 检查端口监听情况
echo ">>> 3. 检查端口监听..."
echo "监听 80 端口的进程:"
sudo netstat -tlnp 2>/dev/null | grep :80 || sudo ss -tlnp 2>/dev/null | grep :80 || echo "端口 80 未监听"

echo "监听 443 端口的进程:"
sudo netstat -tlnp 2>/dev/null | grep :443 || sudo ss -tlnp 2>/dev/null | grep :443 || echo "端口 443 未监听"
echo ""

# 4. 检查是否有 SELinux 阻止
echo ">>> 4. 检查 SELinux..."
if command -v getenforce > /dev/null; then
    SELINUX_STATUS=$(getenforce 2>/dev/null || echo "Unknown")
    echo "SELinux 状态: $SELINUX_STATUS"
    if [ "$SELINUX_STATUS" = "Enforcing" ]; then
        echo "⚠ SELinux 处于强制模式，可能阻止访问"
        echo "临时设置为宽松模式（仅用于测试）..."
        sudo setenforce 0 2>/dev/null || echo "无法修改 SELinux 状态"
    fi
else
    echo "未安装 SELinux"
fi
echo ""

# 5. 清理所有可能有冲突的配置，创建唯一配置
echo ">>> 5. 清理配置并创建唯一配置..."
NGINX_CONF="/etc/nginx/conf.d/my-fullstack-app.conf"

# 备份所有现有配置
sudo mkdir -p /etc/nginx/conf.d/backup.$(date +%Y%m%d_%H%M%S)
sudo cp /etc/nginx/conf.d/*.conf /etc/nginx/conf.d/backup.*/ 2>/dev/null || true

# 删除所有现有配置（除了我们的）
sudo rm -f /etc/nginx/conf.d/*.conf
sudo rm -f /etc/nginx/sites-enabled/* 2>/dev/null || true

# 检查 SSL 证书
if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ] && [ -f "/etc/nginx/ssl/linchuan.tech/privkey.pem" ]; then
    echo "使用 HTTPS 配置"
    sudo tee "$NGINX_CONF" > /dev/null << 'HTTPS_EOF'
upstream backend {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    listen [::]:80;
    server_name linchuan.tech www.linchuan.tech;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name linchuan.tech www.linchuan.tech;
    
    ssl_certificate /etc/nginx/ssl/linchuan.tech/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/linchuan.tech/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
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
    echo "使用 HTTP 配置（SSL 证书不存在）"
    sudo tee "$NGINX_CONF" > /dev/null << 'HTTP_EOF'
upstream backend {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    listen [::]:80;
    server_name linchuan.tech www.linchuan.tech 47.112.29.212;
    
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
HTTP_EOF
fi

echo "✓ 配置已创建"
echo ""

# 6. 测试配置
echo ">>> 6. 测试配置..."
if sudo nginx -t; then
    echo "✓ 配置测试通过"
else
    echo "✗ 配置测试失败:"
    sudo nginx -t 2>&1
    exit 1
fi
echo ""

# 7. 重启服务
echo ">>> 7. 重启服务..."
sudo systemctl restart my-fullstack-app
sleep 3
sudo systemctl restart nginx
sleep 3
echo "✓ 服务已重启"
echo ""

# 8. 验证监听
echo ">>> 8. 验证端口监听..."
sleep 2

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
    echo "⚠ 端口 443 未监听（如果使用 HTTP 配置，这是正常的）"
fi
echo ""

# 9. 测试访问
echo ">>> 9. 测试访问..."
BACKEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
echo "后端直接访问: HTTP $BACKEND_CODE"

if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ]; then
    NGINX_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k https://127.0.0.1/api/health 2>/dev/null || echo "000")
    echo "Nginx HTTPS 访问: HTTP $NGINX_CODE"
else
    NGINX_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/api/health 2>/dev/null || echo "000")
    echo "Nginx HTTP 访问: HTTP $NGINX_CODE"
fi
echo ""

# 10. 检查阿里云安全组提示
echo ">>> 10. 重要提示..."
echo ""
echo "如果服务内部正常但外部无法访问，请检查："
echo ""
echo "1. 阿里云安全组设置："
echo "   - 登录阿里云控制台"
echo "   - 进入 ECS 实例 -> 安全组"
echo "   - 确保入方向规则开放："
echo "     * 端口 80 (HTTP)"
echo "     * 端口 443 (HTTPS)"
echo "     * 协议: TCP"
echo "     * 授权对象: 0.0.0.0/0"
echo ""
echo "2. 服务器公网 IP: 47.112.29.212"
echo "   测试命令: curl http://47.112.29.212/api/health"
echo ""
echo "3. 如果使用 HTTPS，确保域名 DNS 解析正确:"
echo "   linchuan.tech -> 47.112.29.212"
echo ""

echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""

