#!/bin/bash
# 配置强化的 Docker 镜像加速（多个国内源）

set -e

echo "=========================================="
echo "配置 Docker 镜像加速（强化版）"
echo "=========================================="
echo ""

# 配置多个镜像加速源
echo "步骤 1: 配置多个国内镜像加速源..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
        "registry-mirrors": [
    "https://jgz5n894.mirror.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com"
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "insecure-registries": [],
  "experimental": false
}
EOF

echo "✓ 镜像加速配置完成"
echo ""

# 重启 Docker
echo "步骤 2: 重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 5
echo "✓ Docker 已重启"
echo ""

# 验证配置
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
echo "已配置的镜像加速源:"
echo "  1. 中科大镜像: https://docker.mirrors.ustc.edu.cn"
echo "  2. 网易镜像: https://hub-mirror.c.163.com"
echo "  3. 百度云镜像: https://mirror.baidubce.com"
echo "  4. Azure 中国镜像: https://dockerhub.azk8s.cn"
echo "  5. 七牛云镜像: https://reg-mirror.qiniu.com"
echo "  6. 阿里云镜像: https://registry.cn-hangzhou.aliyuncs.com"
echo ""
echo "现在可以尝试拉取镜像，Docker 会自动使用最快的镜像源"
echo ""

