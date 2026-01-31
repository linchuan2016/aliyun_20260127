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

echo "步骤 2: 检查内存..."
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')
echo "总内存: ${TOTAL_MEM}MB, 可用内存: ${AVAIL_MEM}MB"

if [ "$AVAIL_MEM" -lt 500 ]; then
    echo "⚠️  警告: 可用内存不足 500MB，建议使用低内存优化脚本"
    echo "  运行: sudo ./scripts/deploy/install-docker-aliyun-low-memory.sh"
    echo "  或使用官方脚本: curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"
    echo ""
fi

echo "安装必要的依赖..."
# 分批安装，避免一次性安装导致内存不足
echo "  安装 yum-utils..."
sudo yum install -y yum-utils || {
    echo "❌ yum-utils 安装失败，可能是内存不足"
    echo "建议使用: sudo ./scripts/deploy/install-docker-aliyun-low-memory.sh"
    exit 1
}

echo "  安装 device-mapper-persistent-data 和 lvm2..."
sudo yum install -y device-mapper-persistent-data lvm2 || {
    echo "⚠️  可选依赖安装失败，继续安装 Docker（通常不影响使用）..."
}
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

# 检查内存，如果内存充足才运行 hello-world
AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')
if [ "$AVAIL_MEM" -gt 200 ]; then
    echo "运行测试容器..."
    sudo docker run hello-world || echo "⚠️  测试容器运行失败（可能是内存不足），但 Docker 已安装"
else
    echo "⚠️  内存不足，跳过测试容器"
fi
echo "✓ Docker 验证完成"
echo ""

echo "=========================================="
echo "Docker 安装成功！"
echo "=========================================="
echo ""

