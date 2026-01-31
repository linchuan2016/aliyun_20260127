#!/bin/bash
# Milvus 启动脚本（仅使用国内镜像源）

set -e

echo "=========================================="
echo "启动 Milvus 和 Attu（仅使用国内镜像源）"
echo "=========================================="
echo ""

# 步骤 1: 配置仅使用国内镜像源
echo "步骤 1: 配置仅使用国内镜像源..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://huecker.io",
    "https://dockerhub.timless.top",
    "https://noohub.net"
  ],
  "insecure-registries": [],
  "disable-legacy-registry": true
}
EOF

# 完全重启 Docker
echo "重启 Docker..."
sudo systemctl daemon-reload
sudo systemctl stop docker
sleep 5
sudo systemctl start docker
sleep 10
echo "✓ 镜像源已配置"
echo ""

# 验证配置
echo "验证镜像源配置:"
cat /etc/docker/daemon.json
echo ""
sudo docker info | grep -A 10 "Registry Mirrors" || echo "无法获取镜像源信息"
echo ""

# 步骤 2: 拉取镜像（仅使用国内镜像源，不重试）
echo "步骤 2: 拉取镜像（仅使用国内镜像源）..."
IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

for IMAGE in "${IMAGES[@]}"; do
    echo "拉取: $IMAGE"
    sudo timeout 1800 docker pull "$IMAGE" 2>&1
    echo ""
done

# 验证镜像
echo "步骤 3: 验证镜像..."
sudo docker images | grep -E "(etcd|minio|milvus|attu)"
echo ""

# 步骤 4: 创建配置
echo "步骤 4: 创建配置..."
sudo mkdir -p /opt/milvus/volumes/{etcd,minio,milvus}

sudo tee /opt/milvus/docker-compose.yml <<-'COMPOSE_EOF'
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

sudo chown -R $USER:$USER /opt/milvus
sudo chmod -R 755 /opt/milvus

# 步骤 5: 启动服务
echo "步骤 5: 启动服务..."
cd /opt/milvus
sudo docker compose down 2>/dev/null || true
sudo docker compose up -d

# 等待启动
echo "等待服务启动..."
sleep 30

# 检查状态
echo "服务状态:"
sudo docker ps --filter "name=milvus"

SERVER_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "=========================================="
echo "✅ 完成！"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  Attu 管理界面: http://$SERVER_IP:3000"
echo "  Milvus API: $SERVER_IP:19530"
echo "  MinIO 控制台: http://$SERVER_IP:9001"
echo ""

