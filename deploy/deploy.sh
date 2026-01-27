#!/bin/bash
# 快速部署脚本
# 使用方法: sudo bash deploy.sh

set -e

APP_DIR="/var/www/my-fullstack-app"
SERVICE_NAME="my-fullstack-app"

echo "开始部署..."

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 创建应用目录
echo "1. 创建应用目录..."
mkdir -p $APP_DIR
cd $APP_DIR

# 2. 安装系统依赖
echo "2. 安装系统依赖..."
if [ -f /etc/debian_version ]; then
    # Ubuntu/Debian
    apt update
    apt install -y python3 python3-pip python3-venv nginx git
elif [ -f /etc/redhat-release ] || [ -f /etc/alibaba-release ]; then
    # CentOS/RHEL/Alibaba Cloud Linux
    yum update -y
    yum install -y python3 python3-pip python3-devel nginx git
else
    echo "未识别的系统，请手动安装依赖"
    exit 1
fi

# 3. 设置后端
echo "3. 设置后端环境..."
cd $APP_DIR/backend
python3 -m venv ../venv
source ../venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 4. 构建前端
echo "4. 构建前端..."
cd $APP_DIR/frontend
if ! command -v node &> /dev/null; then
    echo "Node.js 未安装，正在安装..."
    if [ -f /etc/debian_version ]; then
        # Ubuntu/Debian
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt install -y nodejs
    elif [ -f /etc/redhat-release ] || [ -f /etc/alibaba-release ]; then
        # CentOS/RHEL/Alibaba Cloud Linux
        curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
        yum install -y nodejs
    fi
fi
npm install
npm run build

# 5. 配置 systemd 服务
echo "5. 配置 systemd 服务..."
cp $APP_DIR/deploy/my-fullstack-app.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable $SERVICE_NAME
systemctl start $SERVICE_NAME

# 6. 配置 Nginx
echo "6. 配置 Nginx..."
if [ -f /etc/debian_version ]; then
    # Ubuntu/Debian: 使用 sites-available
    cp $APP_DIR/deploy/nginx.conf /etc/nginx/sites-available/$SERVICE_NAME
    ln -sf /etc/nginx/sites-available/$SERVICE_NAME /etc/nginx/sites-enabled/
elif [ -f /etc/redhat-release ] || [ -f /etc/alibaba-release ]; then
    # CentOS/RHEL/Alibaba Cloud Linux: 使用 conf.d
    cp $APP_DIR/deploy/nginx.conf /etc/nginx/conf.d/$SERVICE_NAME.conf
fi
nginx -t
systemctl restart nginx

# 7. 配置防火墙
echo "7. 配置防火墙..."
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp
    ufw allow 443/tcp
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-service=https
    firewall-cmd --reload
fi

echo "部署完成！"
echo "请记得："
echo "1. 修改 /etc/systemd/system/$SERVICE_NAME.service 中的域名配置"
echo "2. 修改 /etc/nginx/sites-available/$SERVICE_NAME 中的域名配置"
echo "3. 重启服务: sudo systemctl restart $SERVICE_NAME && sudo systemctl restart nginx"
echo "4. 在阿里云控制台配置安全组，开放 80 和 443 端口"


