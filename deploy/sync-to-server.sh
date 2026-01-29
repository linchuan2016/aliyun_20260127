#!/bin/bash

# 同步代码到阿里云服务器并重启服务
# 使用方法: ./sync-to-server.sh

SERVER_IP="47.112.29.212"
SERVER_USER="root"
DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "开始同步代码到阿里云服务器"
echo "=========================================="
echo ""

# 1. SSH 连接到服务器并拉取最新代码
echo "步骤 1: 拉取最新代码..."
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
cd /var/www/my-fullstack-app

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo "警告: 服务器上有未提交的更改，正在备份..."
    git stash
fi

# 从 Gitee 拉取最新代码
echo "从 Gitee 拉取最新代码..."
git pull gitee main

if [ $? -ne 0 ]; then
    echo "错误: Git pull 失败"
    exit 1
fi

echo "代码拉取成功！"
ENDSSH

if [ $? -ne 0 ]; then
    echo "错误: SSH 连接或代码拉取失败"
    exit 1
fi

echo ""
echo "步骤 2: 更新后端依赖..."
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
cd /var/www/my-fullstack-app/backend

# 激活虚拟环境并更新依赖
source /var/www/my-fullstack-app/venv/bin/activate
pip install -r requirements.txt --quiet

echo "后端依赖更新完成"
ENDSSH

echo ""
echo "步骤 3: 初始化/更新数据库..."
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
cd /var/www/my-fullstack-app/backend

# 激活虚拟环境
source /var/www/my-fullstack-app/venv/bin/activate

# 运行数据库初始化脚本
python init_db.py

echo "数据库更新完成"
ENDSSH

echo ""
echo "步骤 4: 构建前端..."
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
cd /var/www/my-fullstack-app/frontend

# 安装依赖（如果需要）
npm install --silent

# 构建前端
npm run build

echo "前端构建完成"
ENDSSH

echo ""
echo "步骤 5: 重启服务..."
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
# 重启后端服务
systemctl restart my-fullstack-app

# 重启 Nginx
systemctl restart nginx

# 检查服务状态
echo ""
echo "服务状态:"
systemctl status my-fullstack-app --no-pager -l | head -5
systemctl status nginx --no-pager -l | head -5
ENDSSH

echo ""
echo "=========================================="
echo "同步完成！"
echo "=========================================="
echo ""
echo "访问地址: http://47.112.29.212"
echo ""



