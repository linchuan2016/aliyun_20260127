#!/bin/bash
# 配置阿里云 Docker 镜像加速

set -e

echo "=========================================="
echo "配置阿里云 Docker 镜像加速"
echo "=========================================="
echo ""

echo "步骤 1: 配置阿里云镜像加速..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://jgz5n894.mirror.aliyuncs.com"]
}
EOF

echo "✓ 镜像加速配置完成"
echo ""

echo "步骤 2: 重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 5
echo "✓ Docker 已重启"
echo ""

echo "步骤 3: 验证配置..."
echo "Docker 镜像加速配置:"
cat /etc/docker/daemon.json
echo ""

echo "测试镜像拉取..."
if timeout 30 docker pull hello-world &>/dev/null; then
    echo "✓ 镜像拉取测试成功"
    docker rmi hello-world &>/dev/null || true
else
    echo "⚠️  镜像拉取测试超时，但配置已更新"
fi
echo ""

echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "已配置阿里云镜像加速: https://jgz5n894.mirror.aliyuncs.com"
echo "现在可以尝试拉取镜像，Docker 会自动使用阿里云镜像加速"
echo ""

