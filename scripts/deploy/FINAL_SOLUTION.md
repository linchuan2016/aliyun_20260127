# 最终解决方案：解决网络超时问题

## 问题
即使配置了镜像加速，Docker 仍然尝试从 registry-1.docker.io 拉取镜像，导致超时。

## 完整解决方案（在服务器上直接执行）

### 步骤 1: 配置镜像加速并验证

```bash
# 配置多个国内镜像源
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

# 重启 Docker（重要！）
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 10

# 验证配置是否生效
echo "检查镜像加速配置:"
cat /etc/docker/daemon.json
echo ""
echo "检查 Docker 信息:"
docker info | grep -A 10 "Registry Mirrors"
echo ""

# 测试镜像加速是否工作
echo "测试镜像拉取:"
docker pull hello-world
docker rmi hello-world
```

### 步骤 2: 手动拉取镜像（逐个拉取，确保成功）

```bash
# 拉取 etcd（使用 15 分钟超时）
echo "========== 拉取 etcd =========="
timeout 900 docker pull quay.io/coreos/etcd:v3.5.5
echo ""

# 拉取 minio（使用 15 分钟超时）
echo "========== 拉取 minio =========="
timeout 900 docker pull minio/minio:RELEASE.2023-03-20T20-16-18Z
echo ""

# 拉取 milvus（使用 15 分钟超时）
echo "========== 拉取 milvus =========="
timeout 900 docker pull milvusdb/milvus:v2.3.3
echo ""

# 拉取 attu（使用 15 分钟超时）
echo "========== 拉取 attu =========="
timeout 900 docker pull zilliz/attu:v2.3.0
echo ""

# 验证所有镜像已拉取
echo "========== 验证镜像 =========="
docker images | grep -E "(etcd|minio|milvus|attu)"
```

### 步骤 3: 创建配置并启动服务

```bash
# 创建目录
sudo mkdir -p /opt/milvus/volumes/{etcd,minio,milvus}

# 创建 docker-compose.yml
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

# 设置权限
sudo chown -R $USER:$USER /opt/milvus
sudo chmod -R 755 /opt/milvus

# 停止旧服务
cd /opt/milvus
sudo docker compose down 2>/dev/null || true

# 启动服务（此时镜像已拉取，不会超时）
sudo docker compose up -d

# 等待启动
sleep 30

# 检查状态
sudo docker ps --filter "name=milvus"
```

## 一键执行脚本

如果上面的步骤太复杂，可以使用这个一键脚本：

```bash
cat > /tmp/start-milvus-final.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e

echo "配置镜像加速..."
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
sleep 10

echo "拉取镜像..."
for img in "quay.io/coreos/etcd:v3.5.5" "minio/minio:RELEASE.2023-03-20T20-16-18Z" "milvusdb/milvus:v2.3.3" "zilliz/attu:v2.3.0"; do
    echo "拉取: $img"
    timeout 900 docker pull "$img" || echo "失败: $img"
done

echo "创建配置..."
sudo mkdir -p /opt/milvus/volumes/{etcd,minio,milvus}
# ... (docker-compose.yml 内容同上)

echo "启动服务..."
cd /opt/milvus
sudo docker compose up -d
sleep 30
sudo docker ps --filter "name=milvus"
SCRIPT_EOF

chmod +x /tmp/start-milvus-final.sh
sudo /tmp/start-milvus-final.sh
```

## 关键点

1. **必须重启 Docker**: 配置镜像加速后必须重启 Docker 才能生效
2. **先拉取后启动**: 确保所有镜像都已拉取成功，再启动服务
3. **增加超时时间**: 使用 15 分钟（900 秒）超时
4. **验证配置**: 使用 `docker info` 验证镜像加速是否生效

