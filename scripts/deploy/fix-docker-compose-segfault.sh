#!/bin/bash
# 修复 docker-compose ps 的 Segmentation fault 问题

echo "=========================================="
echo "修复 docker-compose Segmentation fault"
echo "=========================================="
echo ""

# 检查 docker-compose 版本
echo "步骤 1: 检查 Docker Compose 版本..."
if command -v docker-compose &> /dev/null; then
    echo "使用 docker-compose (旧版本)"
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    echo "使用 docker compose (新版本)"
    COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose 未安装"
    exit 1
fi
echo ""

# 方法 1: 使用 docker ps 代替 docker-compose ps
echo "步骤 2: 使用替代方法查看容器状态..."
echo "使用 'docker ps' 代替 'docker-compose ps':"
docker ps --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 方法 2: 检查并重新安装 docker-compose
echo "步骤 3: 检查 Docker Compose 安装..."
if [ "$COMPOSE_CMD" = "docker-compose" ]; then
    echo "检测到旧版 docker-compose，建议使用新版 'docker compose'"
    echo ""
    echo "如果问题持续，可以尝试："
    echo "  1. 使用 'docker compose' (新版，不需要单独安装)"
    echo "  2. 或重新安装 docker-compose"
fi
echo ""

echo "=========================================="
echo "修复建议"
echo "=========================================="
echo ""
echo "如果 'docker-compose ps' 出现 Segmentation fault，请使用："
echo ""
echo "1. 使用 docker ps 查看容器:"
echo "   docker ps --filter 'name=milvus'"
echo ""
echo "2. 使用新版 docker compose (推荐):"
echo "   docker compose ps"
echo ""
echo "3. 查看服务日志:"
echo "   docker logs milvus-standalone"
echo "   docker logs milvus-attu"
echo "   docker logs milvus-etcd"
echo "   docker logs milvus-minio"
echo ""

