#!/bin/bash
# 从国内镜像源直接拉取镜像（绕过 Docker Hub）

set -e

echo "=========================================="
echo "从国内镜像源拉取 Milvus 镜像"
echo "=========================================="
echo ""

# 配置镜像加速
echo "步骤 1: 配置国内镜像加速..."
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
echo "✓ 镜像加速已配置"
echo ""

# 镜像列表（使用原始镜像名，通过镜像加速拉取）
IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

echo "步骤 2: 拉取镜像（使用国内镜像加速）..."
echo ""

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
        
        # 使用更长的超时时间
        if timeout 900 docker pull "$IMAGE" 2>&1 | tee /tmp/docker-pull.log; then
            echo "✓ $IMAGE 拉取成功！"
            SUCCESS=true
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            break
        else
            # 检查是否是因为超时
            if grep -q "timeout\|Time.*exceeded\|context canceled" /tmp/docker-pull.log 2>/dev/null; then
                if [ $RETRY -lt $MAX_RETRIES ]; then
                    WAIT_TIME=$((RETRY * 15))
                    echo "⚠️  网络超时，等待 ${WAIT_TIME} 秒后重试..."
                    sleep $WAIT_TIME
                    
                    # 尝试重启 Docker（有时能解决连接问题）
                    if [ $RETRY -eq 2 ]; then
                        echo "  重启 Docker 以刷新连接..."
                        sudo systemctl restart docker
                        sleep 5
                    fi
                else
                    echo "❌ $IMAGE 拉取失败（网络超时，已重试 $MAX_RETRIES 次）"
                    FAIL_COUNT=$((FAIL_COUNT + 1))
                fi
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
    echo "  1. 检查网络连接: ping hub-mirror.c.163.com"
    echo "  2. 验证镜像加速配置: cat /etc/docker/daemon.json"
    echo "  3. 查看 Docker 信息: docker info | grep -A 10 Mirrors"
    echo "  4. 手动重试失败的镜像"
fi
echo ""

