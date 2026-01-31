#!/bin/bash
# Milvus 和 Attu 启动脚本（阿里云）
# 在服务器上执行此脚本来启动 Milvus 和 Attu 服务

set -e

echo "=========================================="
echo "启动 Milvus 和 Attu 服务"
echo "=========================================="
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误: Docker 未安装"
    echo "请先安装 Docker:"
    echo "  sudo ./scripts/deploy/install-docker-aliyun.sh"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ 错误: Docker Compose 未安装"
    echo "请先安装 Docker Compose:"
    echo "  sudo ./scripts/deploy/install-docker-compose.sh"
    exit 1
fi

# 检查并配置 Docker 镜像加速
echo "检查 Docker 镜像加速配置..."
if [ ! -f /etc/docker/daemon.json ] || ! grep -q "registry-mirrors" /etc/docker/daemon.json 2>/dev/null; then
    echo "配置 Docker 镜像加速..."
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com"
  ]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "✓ 镜像加速配置完成，Docker 已重启"
    sleep 3
else
    echo "✓ 镜像加速已配置"
fi
echo ""

# 设置部署目录
MILVUS_DIR="/opt/milvus"
PROJECT_DIR="/var/www/my-fullstack-app"
COMPOSE_FILE="$MILVUS_DIR/docker-compose.yml"

echo "步骤 1: 创建部署目录..."
sudo mkdir -p $MILVUS_DIR/volumes/{etcd,minio,milvus}
echo "✓ 目录创建完成"
echo ""

echo "步骤 2: 复制配置文件..."
# 优先使用国内镜像版本
if [ -f "$PROJECT_DIR/scripts/deploy/milvus-docker-compose-cn.yml" ]; then
    sudo cp "$PROJECT_DIR/scripts/deploy/milvus-docker-compose-cn.yml" "$COMPOSE_FILE"
    echo "✓ 配置文件复制完成（使用国内镜像版本）"
elif [ -f "scripts/deploy/milvus-docker-compose-cn.yml" ]; then
    sudo cp "scripts/deploy/milvus-docker-compose-cn.yml" "$COMPOSE_FILE"
    echo "✓ 配置文件复制完成（使用国内镜像版本）"
elif [ -f "$PROJECT_DIR/scripts/deploy/milvus-docker-compose.yml" ]; then
    sudo cp "$PROJECT_DIR/scripts/deploy/milvus-docker-compose.yml" "$COMPOSE_FILE"
    echo "✓ 配置文件复制完成"
elif [ -f "scripts/deploy/milvus-docker-compose.yml" ]; then
    sudo cp "scripts/deploy/milvus-docker-compose.yml" "$COMPOSE_FILE"
    echo "✓ 配置文件复制完成"
else
    echo "❌ 错误: 未找到 docker-compose 配置文件"
    exit 1
fi
echo ""

echo "步骤 3: 设置目录权限..."
sudo chown -R $USER:$USER $MILVUS_DIR 2>/dev/null || sudo chown -R $(whoami):$(whoami) $MILVUS_DIR
sudo chmod -R 755 $MILVUS_DIR
echo "✓ 权限设置完成"
echo ""

echo "步骤 4: 停止旧服务（如果存在）..."
cd $MILVUS_DIR
if command -v docker-compose &> /dev/null; then
    docker-compose down 2>/dev/null || true
else
    docker compose down 2>/dev/null || true
fi
echo "✓ 清理完成"
echo ""

echo "步骤 5: 启动 Milvus 和 Attu 服务..."
cd $MILVUS_DIR
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    docker compose up -d
fi
echo "✓ 服务启动完成"
echo ""

echo "步骤 6: 等待服务就绪..."
echo "等待 30 秒让服务完全启动..."
sleep 30
echo "✓ 等待完成"
echo ""

echo "步骤 7: 检查服务状态..."
cd $MILVUS_DIR
# 使用 docker ps 代替 docker-compose ps（避免 Segmentation fault）
echo "容器状态:"
docker ps --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || {
    echo "使用 docker compose ps..."
    docker compose ps 2>/dev/null || echo "⚠️  无法查看容器状态，请手动检查: docker ps"
}
echo ""

# 获取服务器 IP
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "YOUR_SERVER_IP")

echo "=========================================="
echo "✅ 服务启动完成！"
echo "=========================================="
echo ""
echo "服务信息:"
echo "  Milvus API:        localhost:19530"
echo "  Attu 管理界面:     http://$SERVER_IP:3000"
echo "  MinIO 控制台:       http://$SERVER_IP:9001"
echo ""
echo "常用命令:"
echo "  查看服务状态:      cd $MILVUS_DIR && docker-compose ps"
echo "  查看服务日志:      cd $MILVUS_DIR && docker-compose logs -f"
echo "  重启服务:          cd $MILVUS_DIR && docker-compose restart"
echo "  停止服务:          cd $MILVUS_DIR && docker-compose down"
echo ""
echo "首次访问 Attu:"
echo "  1. 打开浏览器访问: http://$SERVER_IP:3000"
echo "  2. Milvus 地址填写: localhost:19530 或 $SERVER_IP:19530"
echo "  3. 用户名和密码留空（默认配置）"
echo ""

