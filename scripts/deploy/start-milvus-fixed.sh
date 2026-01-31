#!/bin/bash
# Milvus 和 Attu 启动脚本（修复版）
# 确保 Docker 镜像加速已配置，使用原始镜像名

set -e

echo "=========================================="
echo "启动 Milvus 和 Attu 服务（修复版）"
echo "=========================================="
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装"
    exit 1
fi

# 确保 Docker 镜像加速已配置（优先使用阿里云镜像）
echo "步骤 1: 检查并配置 Docker 镜像加速（阿里云）..."
if [ -f "$PROJECT_DIR/scripts/deploy/configure-aliyun-mirror.sh" ]; then
    chmod +x "$PROJECT_DIR/scripts/deploy/configure-aliyun-mirror.sh"
    sudo "$PROJECT_DIR/scripts/deploy/configure-aliyun-mirror.sh"
elif [ -f "scripts/deploy/configure-aliyun-mirror.sh" ]; then
    chmod +x scripts/deploy/configure-aliyun-mirror.sh
    sudo ./scripts/deploy/configure-aliyun-mirror.sh
else
    # 如果没有脚本，直接配置阿里云镜像加速
    if [ ! -f /etc/docker/daemon.json ] || ! grep -q "jgz5n894.mirror.aliyuncs.com" /etc/docker/daemon.json 2>/dev/null; then
        echo "配置阿里云 Docker 镜像加速..."
        sudo mkdir -p /etc/docker
        sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://jgz5n894.mirror.aliyuncs.com"]
}
EOF
        sudo systemctl daemon-reload
        sudo systemctl restart docker
        sleep 5
        echo "✓ 阿里云镜像加速已配置并重启 Docker"
    else
        echo "✓ 阿里云镜像加速已配置"
    fi
fi
echo ""

# 设置变量
MILVUS_DIR="/opt/milvus"
PROJECT_DIR="/var/www/my-fullstack-app"

# 创建目录
echo "步骤 2: 创建部署目录..."
sudo mkdir -p $MILVUS_DIR/volumes/{etcd,minio,milvus}
echo "✓ 目录创建完成"
echo ""

# 复制配置文件（使用原始版本，通过镜像加速拉取）
echo "步骤 3: 复制配置文件..."
if [ -f "$PROJECT_DIR/scripts/deploy/milvus-docker-compose.yml" ]; then
    sudo cp "$PROJECT_DIR/scripts/deploy/milvus-docker-compose.yml" "$MILVUS_DIR/docker-compose.yml"
elif [ -f "scripts/deploy/milvus-docker-compose.yml" ]; then
    sudo cp "scripts/deploy/milvus-docker-compose.yml" "$MILVUS_DIR/docker-compose.yml"
else
    echo "❌ 未找到 docker-compose.yml 文件"
    exit 1
fi
echo "✓ 配置文件复制完成"
echo ""

# 设置权限
echo "步骤 4: 设置权限..."
sudo chown -R $USER:$USER $MILVUS_DIR 2>/dev/null || sudo chown -R $(whoami):$(whoami) $MILVUS_DIR
sudo chmod -R 755 $MILVUS_DIR
echo "✓ 权限设置完成"
echo ""

# 停止旧服务
echo "步骤 5: 停止旧服务..."
cd $MILVUS_DIR
if docker compose version &> /dev/null; then
    docker compose down 2>/dev/null || true
elif command -v docker-compose &> /dev/null; then
    docker-compose down 2>/dev/null || true
else
    echo "⚠️  Docker Compose 未找到，跳过清理"
fi
echo "✓ 清理完成"
echo ""

# 启动服务
echo "步骤 6: 启动服务..."
cd $MILVUS_DIR
if docker compose version &> /dev/null; then
    echo "使用 docker compose (新版)..."
    docker compose up -d
elif command -v docker-compose &> /dev/null; then
    echo "使用 docker-compose (旧版)..."
    docker-compose up -d
else
    echo "❌ Docker Compose 未安装"
    exit 1
fi
echo "✓ 服务启动完成"
echo ""

# 等待服务启动
echo "步骤 7: 等待服务就绪..."
sleep 30
echo "✓ 等待完成"
echo ""

# 检查状态
echo "步骤 8: 检查服务状态..."
cd $MILVUS_DIR
echo "容器状态:"
docker ps --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
sudo docker ps --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 获取服务器 IP
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "YOUR_SERVER_IP")

echo "=========================================="
echo "✅ 服务启动完成！"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  Milvus API:        $SERVER_IP:19530"
echo "  Attu 管理界面:     http://$SERVER_IP:3000"
echo "  MinIO 控制台:      http://$SERVER_IP:9001"
echo ""

