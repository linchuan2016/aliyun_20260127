#!/bin/bash
# 阿里云服务器 Docker 安装脚本（使用国内镜像源）

set -e

echo "=========================================="
echo "安装 Docker（使用阿里云镜像源）"
echo "=========================================="
echo ""

# 检查是否已安装 Docker
if command -v docker &> /dev/null; then
    echo "✓ Docker 已安装"
    docker --version
    exit 0
fi

echo "步骤 1: 卸载旧版本 Docker（如果存在）..."
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
echo "✓ 清理完成"
echo ""

echo "步骤 2: 安装必要的依赖..."
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
echo "✓ 依赖安装完成"
echo ""

echo "步骤 3: 添加 Docker 仓库（使用阿里云镜像）..."
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
echo "✓ 仓库添加完成"
echo ""

echo "步骤 4: 安装 Docker CE..."
sudo yum install -y docker-ce docker-ce-cli containerd.io
echo "✓ Docker 安装完成"
echo ""

echo "步骤 5: 配置 Docker 镜像加速（阿里云）..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF
echo "✓ 镜像加速配置完成"
echo ""

echo "步骤 6: 启动 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl start docker
sudo systemctl enable docker
echo "✓ Docker 服务启动完成"
echo ""

echo "步骤 7: 验证 Docker 安装..."
sudo docker --version
sudo docker run hello-world
echo "✓ Docker 验证完成"
echo ""

echo "=========================================="
echo "Docker 安装成功！"
echo "=========================================="
echo ""

