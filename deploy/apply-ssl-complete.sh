#!/bin/bash

# 完整的 SSL 配置应用脚本
# 使用方法: sudo ./deploy/apply-ssl-complete.sh

set -e

echo "=========================================="
echo "应用 SSL 配置 - 完整流程"
echo "=========================================="
echo ""

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then 
    echo "错误: 请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 检查证书文件
echo "1. 检查 SSL 证书文件..."
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
echo ""

# 2. 备份现有配置
echo "2. 备份现有配置..."
BACKUP_DIR="/var/www/my-fullstack-app/backup-$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

if [ -f /etc/nginx/sites-available/my-fullstack-app ]; then
    cp /etc/nginx/sites-available/my-fullstack-app $BACKUP_DIR/nginx.conf.backup
    echo "   ✓ Nginx 配置已备份"
fi

if [ -f /etc/systemd/system/my-fullstack-app.service ]; then
    cp /etc/systemd/system/my-fullstack-app.service $BACKUP_DIR/my-fullstack-app.service.backup
    echo "   ✓ systemd 服务配置已备份"
fi
echo ""

# 3. 应用 Nginx SSL 配置
echo "3. 应用 Nginx SSL 配置..."
if [ -f /var/www/my-fullstack-app/deploy/nginx-ssl.conf ]; then
    cp /var/www/my-fullstack-app/deploy/nginx-ssl.conf /etc/nginx/sites-available/my-fullstack-app
    echo "   ✓ Nginx SSL 配置已更新"
else
    echo "   警告: 找不到 nginx-ssl.conf，请确保代码已同步"
    exit 1
fi

# 测试 Nginx 配置
echo "   测试 Nginx 配置..."
if nginx -t; then
    echo "   ✓ Nginx 配置测试通过"
else
    echo "   错误: Nginx 配置测试失败"
    exit 1
fi
echo ""

# 4. 更新 systemd 服务配置
echo "4. 更新 systemd 服务配置..."
if [ -f /var/www/my-fullstack-app/deploy/my-fullstack-app-ssl.service ]; then
    cp /var/www/my-fullstack-app/deploy/my-fullstack-app-ssl.service /etc/systemd/system/my-fullstack-app.service
    systemctl daemon-reload
    echo "   ✓ systemd 服务配置已更新"
else
    echo "   警告: 找不到 my-fullstack-app-ssl.service，请确保代码已同步"
fi
echo ""

# 5. 构建前端
echo "5. 构建前端..."
cd /var/www/my-fullstack-app/frontend
if [ -f package.json ]; then
    echo "   安装依赖..."
    npm install --production=false 2>&1 | tail -5
    
    echo "   构建前端..."
    npm run build
    
    if [ -d dist ]; then
        echo "   ✓ 前端构建成功"
    else
        echo "   错误: 前端构建失败，dist 目录不存在"
        exit 1
    fi
else
    echo "   警告: 找不到 package.json"
fi
echo ""

# 6. 重启服务
echo "6. 重启服务..."
systemctl restart my-fullstack-app
sleep 2

if systemctl is-active --quiet my-fullstack-app; then
    echo "   ✓ 后端服务运行正常"
else
    echo "   ✗ 后端服务未运行，请检查日志: journalctl -u my-fullstack-app -n 50"
fi

systemctl reload nginx
sleep 1

if systemctl is-active --quiet nginx; then
    echo "   ✓ Nginx 运行正常"
else
    echo "   ✗ Nginx 未运行，请检查日志: tail -50 /var/log/nginx/error.log"
fi
echo ""

# 7. 显示服务状态
echo "7. 服务状态:"
systemctl status my-fullstack-app --no-pager -l | head -10
echo ""
systemctl status nginx --no-pager -l | head -10
echo ""

echo "=========================================="
echo "SSL 配置完成！"
echo "=========================================="
echo ""
echo "请访问以下地址验证:"
echo "  - https://linchuan.tech"
echo "  - https://www.linchuan.tech"
echo "  - http://linchuan.tech (应该自动重定向到 HTTPS)"
echo ""
echo "如果遇到问题，请查看日志:"
echo "  - Nginx: tail -f /var/log/nginx/error.log"
echo "  - 后端: journalctl -u my-fullstack-app -f"
echo ""

