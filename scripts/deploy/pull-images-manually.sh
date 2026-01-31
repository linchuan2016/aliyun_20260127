#!/bin/bash
# 手动拉取镜像（使用国内镜像源）

set -e

echo "=========================================="
echo "手动拉取 Milvus 镜像（使用国内镜像源）"
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
    sleep 5
fi

echo "使用国内镜像源拉取镜像..."
echo ""

# 使用阿里云镜像服务拉取镜像
IMAGES=(
    "registry.cn-hangzhou.aliyuncs.com/google_containers/etcd:v3.5.5"
    "registry.cn-hangzhou.aliyuncs.com/minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "registry.cn-hangzhou.aliyuncs.com/milvusdb/milvus:v2.3.3"
    "registry.cn-hangzhou.aliyuncs.com/zilliz/attu:v2.3.0"
)

# 原始镜像名（用于重命名）
ORIGINAL_IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

for i in "${!IMAGES[@]}"; do
    CN_IMAGE=${IMAGES[$i]}
    ORIG_IMAGE=${ORIGINAL_IMAGES[$i]}
    
    echo "拉取镜像: $CN_IMAGE"
    if docker pull "$CN_IMAGE"; then
        echo "✓ 镜像拉取成功"
        
        # 为原始镜像名创建标签
        echo "  创建标签: $ORIG_IMAGE"
        docker tag "$CN_IMAGE" "$ORIG_IMAGE" 2>/dev/null || true
    else
        echo "⚠️  镜像 $CN_IMAGE 拉取失败，尝试原始镜像..."
        docker pull "$ORIG_IMAGE" || echo "  ❌ 原始镜像也拉取失败"
    fi
    echo ""
done

echo "=========================================="
echo "镜像拉取完成！"
echo "=========================================="
echo ""
echo "查看已拉取的镜像:"
docker images | grep -E "(etcd|minio|milvus|attu)" || echo "未找到相关镜像"
echo ""

