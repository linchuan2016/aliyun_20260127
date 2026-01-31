#!/bin/bash
# 带重试机制的镜像拉取脚本

set -e

echo "=========================================="
echo "拉取 Milvus 镜像（带重试机制）"
echo "=========================================="
echo ""

# 确保镜像加速已配置
if [ ! -f /etc/docker/daemon.json ] || ! grep -q "jgz5n894.mirror.aliyuncs.com" /etc/docker/daemon.json 2>/dev/null; then
    echo "配置阿里云镜像加速..."
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
fi

# 镜像列表
IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

SUCCESS_COUNT=0
FAIL_COUNT=0

for IMAGE in "${IMAGES[@]}"; do
    echo "----------------------------------------"
    echo "拉取镜像: $IMAGE"
    echo "----------------------------------------"
    
    RETRY=0
    MAX_RETRIES=5
    SUCCESS=false
    
    while [ $RETRY -lt $MAX_RETRIES ]; do
        RETRY=$((RETRY + 1))
        echo "尝试 $RETRY/$MAX_RETRIES..."
        
        # 使用 timeout 和增加超时时间
        if timeout 600 docker pull "$IMAGE" 2>&1; then
            echo "✓ $IMAGE 拉取成功！"
            SUCCESS=true
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            break
        else
            if [ $RETRY -lt $MAX_RETRIES ]; then
                WAIT_TIME=$((RETRY * 10))
                echo "⚠️  拉取失败，等待 ${WAIT_TIME} 秒后重试..."
                sleep $WAIT_TIME
            else
                echo "❌ $IMAGE 拉取失败（已重试 $MAX_RETRIES 次）"
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        fi
    done
    echo ""
done

echo "=========================================="
echo "拉取完成"
echo "=========================================="
echo ""
echo "成功: $SUCCESS_COUNT 个镜像"
echo "失败: $FAIL_COUNT 个镜像"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo "✓ 所有镜像拉取成功！"
    echo ""
    echo "查看已拉取的镜像:"
    docker images | grep -E "(etcd|minio|milvus|attu)" || sudo docker images | grep -E "(etcd|minio|milvus|attu)"
else
    echo "⚠️  部分镜像拉取失败"
    echo ""
    echo "建议:"
    echo "  1. 检查网络连接"
    echo "  2. 验证镜像加速配置: cat /etc/docker/daemon.json"
    echo "  3. 重启 Docker: sudo systemctl restart docker"
    echo "  4. 手动重试失败的镜像"
fi
echo ""

