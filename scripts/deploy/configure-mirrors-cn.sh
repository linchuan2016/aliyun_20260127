#!/bin/bash
# 配置多个国内镜像加速源

set -e

echo "=========================================="
echo "配置国内 Docker 镜像加速源"
echo "=========================================="
echo ""

echo "步骤 1: 配置多个国内镜像加速源..."
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

echo "✓ 镜像加速配置完成"
echo ""

echo "步骤 2: 重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 5
echo "✓ Docker 已重启"
echo ""

echo "步骤 3: 验证配置..."
cat /etc/docker/daemon.json
echo ""

echo "测试镜像拉取..."
if timeout 60 docker pull hello-world &>/dev/null; then
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
echo "已配置的镜像加速源:"
echo "  1. 网易云镜像: https://hub-mirror.c.163.com"
echo "  2. 中科大镜像: https://docker.mirrors.ustc.edu.cn"
echo "  3. 七牛云镜像: https://reg-mirror.qiniu.com"
echo "  4. 阿里云镜像: https://jgz5n894.mirror.aliyuncs.com"
echo ""

