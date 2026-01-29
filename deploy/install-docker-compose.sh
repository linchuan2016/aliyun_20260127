#!/bin/bash
# Docker Compose 安装脚本（使用国内镜像）

set -e

echo "=========================================="
echo "安装 Docker Compose"
echo "=========================================="
echo ""

# 检查是否已安装 Docker Compose
if command -v docker-compose &> /dev/null; then
    echo "✓ Docker Compose 已安装"
    docker-compose --version
    exit 0
fi

echo "步骤 1: 下载 Docker Compose（使用 GitHub 镜像）..."
# 使用 GitHub 镜像或直接下载
COMPOSE_VERSION="2.20.0"
ARCH=$(uname -m)

# 尝试使用 GitHub 镜像
if [ "$ARCH" = "x86_64" ]; then
    ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="aarch64"
else
    echo "错误: 不支持的架构 $ARCH"
    exit 1
fi

# 使用国内镜像或直接下载
DOWNLOAD_URL="https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"

echo "下载地址: $DOWNLOAD_URL"
sudo curl -L "$DOWNLOAD_URL" -o /usr/local/bin/docker-compose || {
    echo "使用备用方法下载..."
    # 备用方法：使用 wget
    sudo wget -O /usr/local/bin/docker-compose "$DOWNLOAD_URL" || {
        echo "错误: 无法下载 Docker Compose"
        echo "请手动下载: $DOWNLOAD_URL"
        exit 1
    }
}

echo "✓ 下载完成"
echo ""

echo "步骤 2: 设置执行权限..."
sudo chmod +x /usr/local/bin/docker-compose
echo "✓ 权限设置完成"
echo ""

echo "步骤 3: 创建软链接（如果需要）..."
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
echo "✓ 软链接创建完成"
echo ""

echo "步骤 4: 验证安装..."
docker-compose --version
echo "✓ Docker Compose 安装成功"
echo ""

echo "=========================================="
echo "Docker Compose 安装完成！"
echo "=========================================="
echo ""

