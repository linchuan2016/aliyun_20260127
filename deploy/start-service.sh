#!/bin/bash
# 快速启动服务脚本
# 使用方法: sudo bash start-service.sh

set -e

echo "========================================"
echo "  启动全栈应用服务"
echo "========================================"
echo ""

APP_DIR="/var/www/my-fullstack-app"
SERVICE_NAME="my-fullstack-app"
SERVER_IP="47.112.29.212"  # 修改为你的服务器 IP

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 检查前端是否已构建
echo "[1/6] 检查前端构建..."
if [ ! -d "$APP_DIR/frontend/dist" ]; then
    echo "⚠️  前端未构建，正在构建..."
    cd $APP_DIR/frontend
    npm install
    npm run build
    echo "✓ 前端构建完成"
else
    echo "✓ 前端已构建"
fi

# 2. 配置后端服务
echo ""
echo "[2/6] 配置后端服务..."
cp $APP_DIR/deploy/my-fullstack-app.service /etc/systemd/system/

# 修改服务文件中的配置
sed -i "s/User=www-data/User=root/" /etc/systemd/system/$SERVICE_NAME.service
sed -i "s|ALLOWED_ORIGINS=http://your-domain.com,https://your-domain.com|ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP|" /etc/systemd/system/$SERVICE_NAME.service

systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

if systemctl is-active --quiet $SERVICE_NAME; then
    echo "✓ 后端服务启动成功"
else
    echo "✗ 后端服务启动失败，查看日志: sudo journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi

# 3. 安装 Nginx（如果未安装）
echo ""
echo "[3/6] 检查 Nginx..."
if ! command -v nginx &> /dev/null; then
    echo "安装 Nginx..."
    yum install -y nginx
fi

# 4. 配置 Nginx
echo ""
echo "[4/6] 配置 Nginx..."
cp $APP_DIR/deploy/nginx.conf /etc/nginx/conf.d/$SERVICE_NAME.conf

# 修改 server_name
sed -i "s/server_name your-domain.com www.your-domain.com;/server_name $SERVER_IP;/" /etc/nginx/conf.d/$SERVICE_NAME.conf

# 测试配置
if nginx -t; then
    echo "✓ Nginx 配置正确"
else
    echo "✗ Nginx 配置错误"
    exit 1
fi

# 5. 启动 Nginx
echo ""
echo "[5/6] 启动 Nginx..."
systemctl enable nginx
systemctl restart nginx

if systemctl is-active --quiet nginx; then
    echo "✓ Nginx 启动成功"
else
    echo "✗ Nginx 启动失败"
    exit 1
fi

# 6. 配置防火墙
echo ""
echo "[6/6] 配置防火墙..."
if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --add-service=http > /dev/null 2>&1
    firewall-cmd --permanent --add-service=https > /dev/null 2>&1
    firewall-cmd --reload > /dev/null 2>&1
    echo "✓ 防火墙配置完成"
else
    echo "⚠️  firewalld 未运行，跳过防火墙配置"
fi

echo ""
echo "========================================"
echo "  服务启动完成！"
echo "========================================"
echo ""
echo "服务状态："
systemctl status $SERVICE_NAME --no-pager -l | head -3
systemctl status nginx --no-pager -l | head -3
echo ""
echo "访问地址: http://$SERVER_IP"
echo ""
echo "常用命令："
echo "  查看后端日志: sudo journalctl -u $SERVICE_NAME -f"
echo "  查看 Nginx 日志: sudo tail -f /var/log/nginx/my-fullstack-app-error.log"
echo "  重启服务: sudo systemctl restart $SERVICE_NAME && sudo systemctl restart nginx"
echo ""

