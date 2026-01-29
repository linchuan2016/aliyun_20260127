#!/bin/bash

# 一键应用 SSL 配置脚本
# 使用方法: ./apply-ssl-config.sh

set -e

echo "=========================================="
echo "应用 SSL 配置"
echo "=========================================="
echo ""

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "错误: 请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 备份现有配置
echo "1. 备份现有配置..."
if [ -f /etc/nginx/sites-available/my-fullstack-app ]; then
    cp /etc/nginx/sites-available/my-fullstack-app /etc/nginx/sites-available/my-fullstack-app.backup.$(date +%Y%m%d_%H%M%S)
    echo "   ✓ Nginx 配置已备份"
fi

if [ -f /etc/systemd/system/my-fullstack-app.service ]; then
    cp /etc/systemd/system/my-fullstack-app.service /etc/systemd/system/my-fullstack-app.service.backup.$(date +%Y%m%d_%H%M%S)
    echo "   ✓ systemd 服务配置已备份"
fi

# 2. 检查证书文件
echo ""
echo "2. 检查 SSL 证书文件..."
if [ ! -f /etc/nginx/ssl/linchuan.tech/fullchain.pem ]; then
    echo "   错误: 证书文件不存在: /etc/nginx/ssl/linchuan.tech/fullchain.pem"
    echo "   请先上传证书文件"
    exit 1
fi

if [ ! -f /etc/nginx/ssl/linchuan.tech/privkey.pem ]; then
    echo "   错误: 私钥文件不存在: /etc/nginx/ssl/linchuan.tech/privkey.pem"
    echo "   请先上传私钥文件"
    exit 1
fi

echo "   ✓ 证书文件检查通过"

# 3. 复制 Nginx 配置
echo ""
echo "3. 应用 Nginx 配置..."
if [ -f /var/www/my-fullstack-app/deploy/nginx-ssl.conf ]; then
    cp /var/www/my-fullstack-app/deploy/nginx-ssl.conf /etc/nginx/sites-available/my-fullstack-app
    echo "   ✓ Nginx 配置已更新"
else
    echo "   警告: 找不到 nginx-ssl.conf，请手动配置"
fi

# 4. 测试 Nginx 配置
echo ""
echo "4. 测试 Nginx 配置..."
if nginx -t; then
    echo "   ✓ Nginx 配置测试通过"
else
    echo "   错误: Nginx 配置测试失败"
    exit 1
fi

# 5. 更新 systemd 服务配置
echo ""
echo "5. 更新 systemd 服务配置..."
if [ -f /var/www/my-fullstack-app/deploy/my-fullstack-app-ssl.service ]; then
    cp /var/www/my-fullstack-app/deploy/my-fullstack-app-ssl.service /etc/systemd/system/my-fullstack-app.service
    systemctl daemon-reload
    echo "   ✓ systemd 服务配置已更新"
else
    echo "   警告: 找不到 my-fullstack-app-ssl.service，请手动配置"
fi

# 6. 重启服务
echo ""
echo "6. 重启服务..."
systemctl reload nginx
echo "   ✓ Nginx 已重载"

systemctl restart my-fullstack-app
echo "   ✓ 后端服务已重启"

# 7. 检查服务状态
echo ""
echo "7. 检查服务状态..."
if systemctl is-active --quiet nginx; then
    echo "   ✓ Nginx 运行正常"
else
    echo "   ✗ Nginx 未运行"
fi

if systemctl is-active --quiet my-fullstack-app; then
    echo "   ✓ 后端服务运行正常"
else
    echo "   ✗ 后端服务未运行"
fi

echo ""
echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "请访问以下地址验证:"
echo "  - https://linchuan.tech"
echo "  - https://www.linchuan.tech"
echo ""
echo "如果遇到问题，请查看日志:"
echo "  - Nginx: tail -f /var/log/nginx/error.log"
echo "  - 后端: journalctl -u my-fullstack-app -f"
echo ""

