#!/bin/bash
# Milvus 直接启动脚本（不依赖 Git，可直接执行）
# 解决网络超时问题：先拉取镜像，再启动服务

set -e

echo "=========================================="
echo "Milvus 和 Attu 直接启动（解决网络超时）"
echo "=========================================="
echo ""

# 配置多个国内镜像加速源
echo "步骤 1: 配置国内镜像加速（多个源）..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://reg-mirror.qiniu.com",
    "https://jgz5n894.mirror.aliyuncs.com"
  ],
  "max-concurrent-downloads": 10
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 5
echo "✓ 镜像加速已配置（网易、中科大、七牛云、阿里云）"
echo ""

# 创建目录
MILVUS_DIR="/opt/milvus"
echo "步骤 2: 创建部署目录..."
sudo mkdir -p $MILVUS_DIR/volumes/{etcd,minio,milvus}
echo "✓ 目录创建完成"
echo ""

# 创建 docker-compose.yml
echo "步骤 3: 创建 docker-compose.yml..."
sudo tee $MILVUS_DIR/docker-compose.yml <<-'COMPOSE_EOF'
version: '3.5'

services:
  etcd:
    container_name: milvus-etcd
    image: quay.io/coreos/etcd:v3.5.5
    environment:
      - ETCD_AUTO_COMPACTION_MODE=revision
      - ETCD_AUTO_COMPACTION_RETENTION=1000
      - ETCD_QUOTA_BACKEND_BYTES=4294967296
      - ETCD_SNAPSHOT_COUNT=50000
    volumes:
      - ./volumes/etcd:/etcd
    command: etcd -advertise-client-urls=http://127.0.0.1:2379 -listen-client-urls http://0.0.0.0:2379 --data-dir /etcd
    healthcheck:
      test: ["CMD", "etcdctl", "endpoint", "health"]
      interval: 30s
      timeout: 20s
      retries: 3

  minio:
    container_name: milvus-minio
    image: minio/minio:RELEASE.2023-03-20T20-16-18Z
    environment:
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
    ports:
      - "9001:9001"
      - "9000:9000"
    volumes:
      - ./volumes/minio:/minio_data
    command: minio server /minio_data --console-address ":9001"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3

  standalone:
    container_name: milvus-standalone
    image: milvusdb/milvus:v2.3.3
    command: ["milvus", "run", "standalone"]
    security_opt:
      - seccomp:unconfined
    environment:
      ETCD_ENDPOINTS: etcd:2379
      MINIO_ADDRESS: minio:9000
    volumes:
      - ./volumes/milvus:/var/lib/milvus
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9091/healthz"]
      interval: 30s
      start_period: 90s
      timeout: 20s
      retries: 3
    ports:
      - "19530:19530"
      - "9091:9091"
    depends_on:
      - "etcd"
      - "minio"

  attu:
    container_name: milvus-attu
    image: zilliz/attu:v2.3.0
    environment:
      MILVUS_URL: milvus-standalone:19530
    ports:
      - "3000:3000"
    depends_on:
      - "standalone"

networks:
  default:
    name: milvus
COMPOSE_EOF
echo "✓ 配置文件创建完成"
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

# 手动拉取镜像（带重试）
echo "步骤 6: 手动拉取镜像（带重试机制）..."
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
    SUCCESS=false
    
    while [ $RETRY -lt $MAX_RETRIES ]; do
        RETRY=$((RETRY + 1))
        echo "  尝试 $RETRY/$MAX_RETRIES..."
        
        if timeout 900 docker pull "$IMAGE" 2>&1; then
            echo "  ✓ $IMAGE 拉取成功！"
            SUCCESS=true
            break
        else
            if [ $RETRY -lt $MAX_RETRIES ]; then
                WAIT_TIME=$((RETRY * 10))
                echo "  ⚠️  失败，等待 ${WAIT_TIME} 秒后重试..."
                sleep $WAIT_TIME
            else
                echo "  ❌ $IMAGE 拉取失败（已重试 $MAX_RETRIES 次）"
            fi
        fi
    done
    echo ""
done

# 启动服务
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

