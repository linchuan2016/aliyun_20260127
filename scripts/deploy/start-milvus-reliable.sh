#!/bin/bash
# Milvus 和 Attu 可靠启动脚本
# 先手动拉取镜像，再启动服务，避免网络超时

set -e

echo "=========================================="
echo "Milvus 和 Attu 可靠启动（先拉取镜像）"
echo "=========================================="
echo ""

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装"
    exit 1
fi

# 配置阿里云镜像加速
echo "步骤 1: 配置阿里云镜像加速..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://jgz5n894.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 5
echo "✓ 镜像加速已配置"
echo ""

# 设置变量
MILVUS_DIR="/opt/milvus"
PROJECT_DIR="/var/www/my-fullstack-app"

# 创建目录
echo "步骤 2: 创建部署目录..."
sudo mkdir -p $MILVUS_DIR/volumes/{etcd,minio,milvus}
echo "✓ 目录创建完成"
echo ""

# 复制配置文件
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
fi
echo "✓ 清理完成"
echo ""

# 手动拉取镜像（增加超时时间，重试机制）
echo "步骤 6: 手动拉取镜像（使用镜像加速）..."
IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

for IMAGE in "${IMAGES[@]}"; do
    echo "拉取镜像: $IMAGE"
    RETRY=0
    MAX_RETRIES=3
    
    while [ $RETRY -lt $MAX_RETRIES ]; do
        if timeout 300 docker pull "$IMAGE" 2>&1 | tee /tmp/docker-pull.log; then
            echo "✓ $IMAGE 拉取成功"
            break
        else
            RETRY=$((RETRY + 1))
            if [ $RETRY -lt $MAX_RETRIES ]; then
                echo "⚠️  第 $RETRY 次尝试失败，等待 10 秒后重试..."
                sleep 10
            else
                echo "❌ $IMAGE 拉取失败（已重试 $MAX_RETRIES 次）"
                echo "   检查网络连接和镜像加速配置"
                # 继续尝试下一个镜像，不退出
            fi
        fi
    done
    echo ""
done

echo "步骤 7: 启动服务..."
cd $MILVUS_DIR
if docker compose version &> /dev/null; then
    docker compose up -d
elif command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    echo "❌ Docker Compose 未安装"
    exit 1
fi
echo "✓ 服务启动完成"
echo ""

# 等待服务启动
echo "步骤 8: 等待服务就绪..."
sleep 30
echo "✓ 等待完成"
echo ""

# 检查状态
echo "步骤 9: 检查服务状态..."
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

