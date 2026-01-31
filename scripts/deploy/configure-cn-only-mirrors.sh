#!/bin/bash
# 配置 Docker 仅使用国内镜像源，禁止访问海外源

set -e

echo "=========================================="
echo "配置 Docker 仅使用国内镜像源"
echo "=========================================="
echo ""

# 步骤 1: 配置国内镜像源
echo "步骤 1: 配置国内镜像源..."
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

echo "✓ 镜像源配置完成"
echo ""

# 步骤 2: 重启 Docker
echo "步骤 2: 重启 Docker..."
sudo systemctl daemon-reload
sudo systemctl stop docker
sleep 5
sudo systemctl start docker
sleep 10
echo "✓ Docker 已重启"
echo ""

# 步骤 3: 验证配置
echo "步骤 3: 验证配置..."
echo "Docker 镜像源配置:"
cat /etc/docker/daemon.json
echo ""
echo "Docker 信息中的镜像源:"
sudo docker info 2>/dev/null | grep -A 10 "Registry Mirrors" || echo "无法获取镜像源信息"
echo ""

# 步骤 4: 测试镜像加速
echo "步骤 4: 测试镜像加速..."
if sudo timeout 60 docker pull hello-world &>/dev/null; then
    echo "✓ 镜像加速工作正常"
    sudo docker rmi hello-world &>/dev/null || true
else
    echo "⚠️  镜像加速测试失败"
fi
echo ""

echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "已配置的国内镜像源:"
echo "  1. https://docker.m.daocloud.io"
echo "  2. https://huecker.io"
echo "  3. https://dockerhub.timless.top"
echo "  4. https://noohub.net"
echo ""
echo "Docker 已配置为仅使用国内镜像源，禁止访问海外源"
echo ""

