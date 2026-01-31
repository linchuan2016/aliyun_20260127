#!/bin/bash
# 使用国内镜像加速拉取 Milvus 镜像

set -e

echo "=========================================="
echo "使用国内镜像加速拉取 Milvus 镜像"
echo "=========================================="
echo ""

# 确保镜像加速已配置
if [ ! -f /etc/docker/daemon.json ] || ! grep -q "registry-mirrors" /etc/docker/daemon.json 2>/dev/null; then
    echo "配置 Docker 镜像加速..."
    chmod +x scripts/deploy/configure-docker-mirrors-strong.sh
    sudo ./scripts/deploy/configure-docker-mirrors-strong.sh
fi

echo "开始拉取镜像（使用镜像加速）..."
echo ""

# 镜像列表
IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

# 拉取镜像（Docker 会自动使用配置的镜像加速）
for IMAGE in "${IMAGES[@]}"; do
    echo "拉取镜像: $IMAGE"
    echo "----------------------------------------"
    if timeout 300 docker pull "$IMAGE"; then
        echo "✓ $IMAGE 拉取成功"
    else
        echo "⚠️  $IMAGE 拉取超时或失败"
        echo "   尝试使用 sudo..."
        if timeout 300 sudo docker pull "$IMAGE"; then
            echo "✓ $IMAGE 拉取成功（使用 sudo）"
        else
            echo "❌ $IMAGE 拉取失败，请检查网络连接"
        fi
    fi
    echo ""
done

echo "=========================================="
echo "镜像拉取完成！"
echo "=========================================="
echo ""
echo "查看已拉取的镜像:"
docker images | grep -E "(etcd|minio|milvus|attu)" || sudo docker images | grep -E "(etcd|minio|milvus|attu)"
echo ""

