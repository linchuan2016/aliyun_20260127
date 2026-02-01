#!/bin/bash
# 强制同步代码到服务器（在服务器上执行）
# 使用方法: 在服务器上执行: bash force-sync-to-server.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "🔄 强制同步代码"
echo "=========================================="
echo ""

cd "$DEPLOY_PATH"

# 检查是否是 Git 仓库
if [ ! -d ".git" ]; then
    echo "❌ 当前目录不是 Git 仓库"
    exit 1
fi

# 保存当前工作目录的修改（如果有）
echo ">>> 步骤 1: 保存本地修改..."
if [ -n "$(git status --porcelain)" ]; then
    echo "检测到本地修改，正在保存..."
    git stash push -m "backup-$(date +%Y%m%d_%H%M%S)" || true
fi

# 强制拉取最新代码
echo ""
echo ">>> 步骤 2: 强制拉取最新代码..."
git fetch origin --force
git reset --hard origin/main
git clean -fd

echo ""
echo ">>> 步骤 3: 检查部署脚本..."
if [ -f "scripts/deploy/deploy-docker-aliyun.sh" ]; then
    echo "✓ deploy-docker-aliyun.sh 存在"
    chmod +x scripts/deploy/deploy-docker-aliyun.sh
else
    echo "❌ deploy-docker-aliyun.sh 不存在"
fi

if [ -f "scripts/deploy/deploy-docker-aliyun-quick.sh" ]; then
    echo "✓ deploy-docker-aliyun-quick.sh 存在"
    chmod +x scripts/deploy/deploy-docker-aliyun-quick.sh
else
    echo "❌ deploy-docker-aliyun-quick.sh 不存在"
fi

if [ -f "scripts/deploy/deploy-docker-aliyun-server.sh" ]; then
    echo "✓ deploy-docker-aliyun-server.sh 存在"
    chmod +x scripts/deploy/deploy-docker-aliyun-server.sh
else
    echo "❌ deploy-docker-aliyun-server.sh 不存在"
fi

echo ""
echo ">>> 步骤 4: 检查 docker-compose.yml..."
if [ -f "docker-compose.yml" ]; then
    echo "✓ docker-compose.yml 存在"
else
    echo "❌ docker-compose.yml 不存在"
fi

echo ""
echo "=========================================="
echo "✅ 同步完成！"
echo "=========================================="
echo ""
echo "现在可以执行部署脚本:"
echo "  sudo bash scripts/deploy/deploy-docker-aliyun.sh"
echo ""

