#!/bin/bash
# 修复 Docker 镜像拉取超时问题

set -e

echo "=========================================="
echo "修复 Docker 镜像拉取超时问题"
echo "=========================================="
echo ""

# 1. 配置多个镜像加速源
echo "步骤 1: 配置 Docker 镜像加速（多个源）..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com",
    "https://hub-mirror.c.163.com"
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

echo "✓ 镜像加速配置完成"
echo ""

# 2. 重启 Docker
echo "步骤 2: 重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 5
echo "✓ Docker 已重启"
echo ""

# 3. 验证配置
echo "步骤 3: 验证配置..."
echo "Docker 镜像加速配置:"
cat /etc/docker/daemon.json
echo ""

echo "Docker 信息中的镜像源:"
docker info 2>/dev/null | grep -A 10 "Registry Mirrors" || echo "  无法获取镜像源信息（可能需要等待）"
echo ""

# 4. 测试镜像拉取
echo "步骤 4: 测试镜像拉取..."
echo "拉取测试镜像 hello-world..."
if docker pull hello-world 2>&1 | head -5; then
    echo "✓ 镜像拉取测试成功"
else
    echo "⚠️  镜像拉取测试失败，但继续..."
fi
echo ""

echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "如果仍然超时，请使用国内镜像版本的 docker-compose 文件:"
echo "  sudo cp scripts/deploy/milvus-docker-compose-cn.yml /opt/milvus/docker-compose.yml"
echo "  cd /opt/milvus && docker-compose up -d"
echo ""

