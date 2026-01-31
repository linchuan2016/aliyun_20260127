#!/bin/bash
# 手动拉取 Milvus 和 Attu 所需镜像（使用镜像加速）

set -e

echo "=========================================="
echo "拉取 Milvus 和 Attu 所需镜像"
echo "=========================================="
echo ""

# 确保 Docker 镜像加速已配置
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
    sleep 3
fi

echo "开始拉取镜像..."
echo ""

# 拉取镜像（使用国内镜像源）
IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

for IMAGE in "${IMAGES[@]}"; do
    echo "拉取镜像: $IMAGE"
    docker pull "$IMAGE" || {
        echo "⚠️  镜像 $IMAGE 拉取失败，继续尝试下一个..."
    }
    echo ""
done

echo "=========================================="
echo "镜像拉取完成！"
echo "=========================================="
echo ""
echo "查看已拉取的镜像:"
docker images | grep -E "(etcd|minio|milvus|attu)"
echo ""

