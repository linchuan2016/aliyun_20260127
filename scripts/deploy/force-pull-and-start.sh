#!/bin/bash
# 强制拉取镜像并启动服务（确保镜像加速生效）

set -e

echo "=========================================="
echo "强制拉取镜像并启动 Milvus"
echo "=========================================="
echo ""

# 步骤 1: 配置镜像加速
echo "步骤 1: 配置镜像加速..."
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

# 强制重启 Docker
echo "重启 Docker..."
sudo systemctl daemon-reload
sudo systemctl stop docker
sleep 3
sudo systemctl start docker
sleep 10

# 验证镜像加速
echo "验证镜像加速配置:"
cat /etc/docker/daemon.json
echo ""
echo "Docker 镜像源信息:"
docker info 2>/dev/null | grep -A 10 "Registry Mirrors" || echo "无法获取镜像源信息"
echo ""

# 步骤 2: 强制拉取镜像（使用镜像加速）
echo "步骤 2: 强制拉取镜像..."
IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

ALL_SUCCESS=true

for IMAGE in "${IMAGES[@]}"; do
    echo "----------------------------------------"
    echo "拉取: $IMAGE"
    echo "----------------------------------------"
    
    # 先删除旧镜像（如果有）
    docker rmi "$IMAGE" 2>/dev/null || true
    
    # 拉取镜像（20分钟超时）
    RETRY=0
    MAX_RETRIES=3
    SUCCESS=false
    
    while [ $RETRY -lt $MAX_RETRIES ]; do
        RETRY=$((RETRY + 1))
        echo "尝试 $RETRY/$MAX_RETRIES..."
        
        if timeout 1200 docker pull "$IMAGE" 2>&1; then
            echo "✓ $IMAGE 拉取成功！"
            SUCCESS=true
            break
        else
            if [ $RETRY -lt $MAX_RETRIES ]; then
                WAIT_TIME=$((RETRY * 20))
                echo "⚠️  失败，等待 ${WAIT_TIME} 秒后重试..."
                sleep $WAIT_TIME
                
                # 第二次重试时重启 Docker
                if [ $RETRY -eq 2 ]; then
                    echo "  重启 Docker 以刷新连接..."
                    sudo systemctl restart docker
                    sleep 10
                fi
            else
                echo "❌ $IMAGE 拉取失败（已重试 $MAX_RETRIES 次）"
                ALL_SUCCESS=false
            fi
        fi
    done
    echo ""
done

# 验证镜像
echo "步骤 3: 验证已拉取的镜像..."
docker images | grep -E "(etcd|minio|milvus|attu)" || sudo docker images | grep -E "(etcd|minio|milvus|attu)"
echo ""

if [ "$ALL_SUCCESS" = false ]; then
    echo "⚠️  部分镜像拉取失败，但继续启动服务..."
    echo "   如果服务启动失败，请手动重试失败的镜像"
    echo ""
fi

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

