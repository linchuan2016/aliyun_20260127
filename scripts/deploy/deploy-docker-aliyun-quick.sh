#!/bin/bash
# 阿里云 Docker 快速部署脚本（已安装 Docker 的情况下）
# 使用方法: 在阿里云服务器上执行: bash scripts/deploy/deploy-docker-aliyun-quick.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "🚀 快速部署 Docker 服务"
echo "=========================================="
echo ""

cd "$DEPLOY_PATH"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先运行: bash scripts/deploy/deploy-docker-aliyun.sh"
    exit 1
fi

# 检查 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose 未安装，请先运行: bash scripts/deploy/deploy-docker-aliyun.sh"
    exit 1
fi

# 停止旧服务
echo ">>> 停止旧服务..."
docker-compose down 2>/dev/null || true

# 创建必要目录
mkdir -p data/article-covers data/book-covers
chmod -R 755 data

# 构建并启动
echo ">>> 构建并启动服务..."
docker-compose build
docker-compose up -d

# 等待服务启动
echo ">>> 等待服务启动..."
sleep 15

# 验证
echo ">>> 验证服务..."
if curl -f http://localhost:8000/api/health &>/dev/null; then
    echo "✅ 后端服务正常"
else
    echo "⚠️  后端服务可能未完全启动"
fi

echo ""
echo "✅ 部署完成！"
echo "查看服务状态: docker-compose ps"
echo "查看日志: docker-compose logs -f"

