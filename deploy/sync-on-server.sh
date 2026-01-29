#!/bin/bash
# 在阿里云服务器上执行的同步脚本
# 使用方法: 在服务器上执行以下命令

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "开始同步代码并启动服务"
echo "=========================================="
echo ""

# 步骤 1: 拉取最新代码
echo "步骤 1: 从 Gitee 拉取最新代码..."
cd $DEPLOY_PATH
git pull gitee main
echo "代码拉取成功！"
echo ""

# 步骤 2: 更新后端依赖
echo "步骤 2: 更新后端依赖..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
pip install -r requirements.txt --quiet
echo "后端依赖更新完成"
echo ""

# 步骤 3: 初始化/更新数据库
echo "步骤 3: 初始化/更新数据库..."
python init_db.py
echo "数据库更新完成"
echo ""

# 步骤 4: 构建前端
echo "步骤 4: 构建前端..."
cd $DEPLOY_PATH/frontend
npm install --silent
npm run build
echo "前端构建完成"
echo ""

# 步骤 5: 重启服务
echo "步骤 5: 重启服务..."
systemctl restart my-fullstack-app
systemctl restart nginx
sleep 2

echo ""
echo "=========================================="
echo "同步完成！"
echo "=========================================="
echo ""
echo "服务状态:"
systemctl status my-fullstack-app --no-pager -l | head -10
echo ""
systemctl status nginx --no-pager -l | head -10
echo ""
echo "访问地址:"
echo "  HTTP:  http://47.112.29.212"
echo "  HTTPS: https://linchuan.tech"
echo ""

