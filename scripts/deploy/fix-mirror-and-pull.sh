#!/bin/bash
# 修复镜像加速配置并强制拉取镜像

set -e

echo "=========================================="
echo "修复镜像加速并拉取镜像"
echo "=========================================="
echo ""

# 步骤 1: 使用简化的镜像加速配置
echo "步骤 1: 配置镜像加速（简化版）..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://hub-mirror.c.163.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF

# 完全停止并重启 Docker
echo "完全重启 Docker..."
sudo systemctl stop docker
sleep 5
sudo systemctl start docker
sleep 10

# 验证配置
echo "验证镜像加速配置:"
cat /etc/docker/daemon.json
echo ""
echo "检查 Docker 信息:"
sudo docker info | grep -A 5 "Registry Mirrors" || echo "无法获取镜像源信息"
echo ""

# 测试镜像加速是否工作
echo "测试镜像加速..."
if sudo timeout 60 docker pull hello-world &>/dev/null; then
    echo "✓ 镜像加速工作正常"
    sudo docker rmi hello-world &>/dev/null || true
else
    echo "⚠️  镜像加速测试失败，但继续..."
fi
echo ""

# 步骤 2: 拉取镜像（使用 sudo，增加超时时间）
echo "步骤 2: 拉取 Milvus 镜像..."
IMAGES=(
    "quay.io/coreos/etcd:v3.5.5"
    "minio/minio:RELEASE.2023-03-20T20-16-18Z"
    "milvusdb/milvus:v2.3.3"
    "zilliz/attu:v2.3.0"
)

for IMAGE in "${IMAGES[@]}"; do
    echo "----------------------------------------"
    echo "拉取: $IMAGE"
    echo "----------------------------------------"
    
    # 使用更长的超时时间，并显示详细输出
    RETRY=0
    MAX_RETRIES=5
    SUCCESS=false
    
    while [ $RETRY -lt $MAX_RETRIES ]; do
        RETRY=$((RETRY + 1))
        echo "尝试 $RETRY/$MAX_RETRIES..."
        
        # 使用 sudo 和更长的超时时间
        if sudo timeout 1800 docker pull "$IMAGE" 2>&1 | tee /tmp/docker-pull.log; then
            echo "✓ $IMAGE 拉取成功！"
            SUCCESS=true
            break
        else
            # 检查日志，看是否使用了镜像加速
            if grep -q "registry-1.docker.io" /tmp/docker-pull.log 2>/dev/null; then
                echo "⚠️  仍然访问 Docker Hub，镜像加速可能未生效"
                echo "   重新配置并重启 Docker..."
                sudo systemctl restart docker
                sleep 10
            fi
            
            if [ $RETRY -lt $MAX_RETRIES ]; then
                WAIT_TIME=$((RETRY * 30))
                echo "等待 ${WAIT_TIME} 秒后重试..."
                sleep $WAIT_TIME
            else
                echo "❌ $IMAGE 拉取失败（已重试 $MAX_RETRIES 次）"
            fi
        fi
    done
    echo ""
done

# 验证镜像
echo "步骤 3: 验证已拉取的镜像..."
sudo docker images | grep -E "(etcd|minio|milvus|attu)"
echo ""

echo "=========================================="
echo "镜像拉取完成！"
echo "=========================================="
echo ""

