#!/bin/bash
# 修复 Nginx 配置并应用（解决重复 upstream 和 /data/ 代理问题）
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/修复Nginx配置并应用.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"
NGINX_CONF="/etc/nginx/conf.d/my-fullstack-app.conf"

echo "=========================================="
echo "修复 Nginx 配置并应用"
echo "=========================================="
echo ""

cd "$DEPLOY_PATH"

# 1. 修复图片文件权限（解决 Git reset 权限问题）
echo ">>> 1. 修复图片文件权限..."
SERVICE_USER=$(ps aux | grep '[u]vicorn' | head -1 | awk '{print $1}' || echo "www-data")
if [ -z "$SERVICE_USER" ] || [ "$SERVICE_USER" = "root" ]; then
    SERVICE_USER=$(systemctl show -p User my-fullstack-app 2>/dev/null | cut -d= -f2 || echo "www-data")
fi

echo "服务用户: $SERVICE_USER"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" data/ 2>/dev/null || sudo chown -R "$(whoami):$(whoami)" data/
sudo chmod -R 755 data/
echo "✓ 权限已修复"
echo ""

# 2. 检查当前 Nginx 配置
echo ">>> 2. 检查当前 Nginx 配置..."
if [ -f "$NGINX_CONF" ]; then
    echo "当前配置文件: $NGINX_CONF"
    echo "检查是否有重复的 upstream..."
    
    # 检查重复的 upstream
    if grep -c "^upstream attu" "$NGINX_CONF" | grep -q "^2"; then
        echo "⚠ 发现重复的 upstream attu，需要修复"
    fi
else
    echo "⚠ 配置文件不存在: $NGINX_CONF"
fi
echo ""

# 3. 备份当前配置
echo ">>> 3. 备份当前配置..."
if [ -f "$NGINX_CONF" ]; then
    sudo cp "$NGINX_CONF" "${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ 配置已备份"
fi
echo ""

# 4. 检测使用 HTTPS 还是 HTTP
echo ">>> 4. 检测配置类型..."
if [ -f "/etc/nginx/ssl/linchuan.tech/fullchain.pem" ]; then
    echo "检测到 SSL 证书，使用 HTTPS 配置"
    CONFIG_FILE="scripts/deploy/nginx-ssl.conf"
else
    echo "未检测到 SSL 证书，使用 HTTP 配置"
    CONFIG_FILE="scripts/deploy/nginx.conf"
fi
echo ""

# 5. 应用新配置
echo ">>> 5. 应用新配置..."
sudo cp "$CONFIG_FILE" "$NGINX_CONF"
echo "✓ 配置已复制"
echo ""

# 6. 检查并修复重复的 upstream（如果存在）
echo ">>> 6. 检查配置语法..."
if sudo nginx -t 2>&1 | grep -q "duplicate upstream"; then
    echo "⚠ 发现重复的 upstream，正在修复..."
    
    # 创建一个临时文件，移除重复的 upstream
    sudo python3 << 'FIX_UPSTREAM_EOF'
import re

conf_file = "/etc/nginx/conf.d/my-fullstack-app.conf"

with open(conf_file, 'r', encoding='utf-8') as f:
    content = f.read()

# 查找所有 upstream 块
upstream_blocks = {}
lines = content.split('\n')
new_lines = []
in_upstream = False
current_upstream = None
upstream_start = -1

i = 0
while i < len(lines):
    line = lines[i]
    
    # 检测 upstream 开始
    if re.match(r'^\s*upstream\s+(\w+)\s*\{', line):
        upstream_name = re.match(r'^\s*upstream\s+(\w+)\s*\{', line).group(1)
        if upstream_name in upstream_blocks:
            # 这是重复的，跳过整个块
            print(f"跳过重复的 upstream: {upstream_name}")
            in_upstream = True
            current_upstream = upstream_name
            i += 1
            # 跳过直到找到对应的 }
            brace_count = 1
            while i < len(lines) and brace_count > 0:
                if '{' in lines[i]:
                    brace_count += lines[i].count('{')
                if '}' in lines[i]:
                    brace_count -= lines[i].count('}')
                i += 1
            continue
        else:
            # 第一次出现，保留
            upstream_blocks[upstream_name] = True
            new_lines.append(line)
            in_upstream = True
            current_upstream = upstream_name
    elif in_upstream:
        new_lines.append(line)
        if '}' in line:
            brace_count = line.count('}')
            if brace_count > 0:
                in_upstream = False
                current_upstream = None
    else:
        new_lines.append(line)
    
    i += 1

# 写回文件
with open(conf_file, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))

print("✓ 重复的 upstream 已移除")
FIX_UPSTREAM_EOF
    
    echo "✓ 修复完成"
fi
echo ""

# 7. 测试 Nginx 配置
echo ">>> 7. 测试 Nginx 配置..."
if sudo nginx -t; then
    echo "✓ Nginx 配置测试通过"
else
    echo "✗ Nginx 配置测试失败"
    echo "查看错误信息："
    sudo nginx -t 2>&1
    exit 1
fi
echo ""

# 8. 重启 Nginx
echo ">>> 8. 重启 Nginx..."
sudo systemctl reload nginx
sleep 2
echo "✓ Nginx 已重启"
echo ""

# 9. 验证配置
echo ">>> 9. 验证配置..."
echo "检查 /data/ location 是否存在："
if grep -A 5 "location /data/" "$NGINX_CONF" | grep -q "proxy_pass"; then
    echo "✓ /data/ location 配置正确"
    grep -A 5 "location /data/" "$NGINX_CONF"
else
    echo "✗ /data/ location 配置缺失或错误"
fi
echo ""

# 10. 测试图片访问
echo ">>> 10. 测试图片访问..."
echo "测试后端直接访问:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/data/book-covers/s3259913.jpg 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ 后端直接访问正常 (HTTP $HTTP_CODE)"
else
    echo "✗ 后端直接访问失败 (HTTP $HTTP_CODE)"
fi

echo ""
echo "测试通过 Nginx HTTP 访问:"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/data/book-covers/s3259913.jpg 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ]; then
    echo "✓ Nginx HTTP 访问正常 (HTTP $HTTP_CODE)"
    if [ "$HTTP_CODE" = "301" ]; then
        echo "  (重定向到 HTTPS，这是正常的)"
    fi
else
    echo "✗ Nginx HTTP 访问失败 (HTTP $HTTP_CODE)"
fi

echo ""
echo "测试通过 Nginx HTTPS 访问:"
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k https://127.0.0.1/data/book-covers/s3259913.jpg 2>/dev/null || echo "000")
if [ "$HTTPS_CODE" = "200" ]; then
    echo "✓ Nginx HTTPS 访问正常 (HTTP $HTTPS_CODE)"
else
    echo "✗ Nginx HTTPS 访问失败 (HTTP $HTTPS_CODE)"
    echo "  请检查 HTTPS 配置中的 /data/ location"
fi

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "如果 HTTPS 仍然无法访问，请检查："
echo "1. Nginx 配置中的 /data/ location 是否在正确的位置（应该在 /api/ 之后）"
echo "2. 查看 Nginx 错误日志: sudo tail -n 50 /var/log/nginx/my-fullstack-app-error.log"
echo "3. 查看 Nginx 访问日志: sudo tail -n 50 /var/log/nginx/my-fullstack-app-access.log"
echo ""

