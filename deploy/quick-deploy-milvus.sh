#!/bin/bash
# Milvus 和 Attu 快速部署脚本（一键执行）
# 在阿里云服务器上执行此脚本

set -e

echo "=========================================="
echo "Milvus 和 Attu 快速部署"
echo "=========================================="
echo ""

# 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo "安装 Docker（使用阿里云镜像源）..."
    if [ -f "deploy/install-docker-aliyun.sh" ]; then
        chmod +x deploy/install-docker-aliyun.sh
        sudo ./deploy/install-docker-aliyun.sh
    else
        echo "使用 yum 安装 Docker..."
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "✓ Docker 安装完成"
    fi
else
    echo "✓ Docker 已安装"
fi

# 检查并安装 Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "安装 Docker Compose..."
    if [ -f "deploy/install-docker-compose.sh" ]; then
        chmod +x deploy/install-docker-compose.sh
        sudo ./deploy/install-docker-compose.sh
    else
        COMPOSE_VERSION="2.20.0"
        ARCH=$(uname -m)
        sudo curl -L "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${ARCH}" -o /usr/local/bin/docker-compose || {
            echo "使用 wget 下载..."
            sudo wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"
        }
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
        echo "✓ Docker Compose 安装完成"
    fi
else
    echo "✓ Docker Compose 已安装"
fi

# 设置部署目录
MILVUS_DIR="/opt/milvus"
PROJECT_DIR="/var/www/my-fullstack-app"

echo ""
echo "步骤 1: 创建部署目录..."
sudo mkdir -p $MILVUS_DIR/volumes/{etcd,minio,milvus}
echo "✓ 目录创建完成"

echo ""
echo "步骤 2: 复制配置文件..."
if [ -f "$PROJECT_DIR/deploy/milvus-docker-compose.yml" ]; then
    sudo cp $PROJECT_DIR/deploy/milvus-docker-compose.yml $MILVUS_DIR/docker-compose.yml
    echo "✓ 配置文件复制完成"
else
    echo "错误: 未找到 docker-compose.yml 文件"
    echo "请确保项目代码已同步到服务器"
    exit 1
fi

echo ""
echo "步骤 3: 设置权限..."
sudo chown -R $USER:$USER $MILVUS_DIR
sudo chmod -R 755 $MILVUS_DIR
echo "✓ 权限设置完成"

echo ""
echo "步骤 4: 启动服务..."
cd $MILVUS_DIR
docker-compose down 2>/dev/null || true
docker-compose up -d
echo "✓ 服务启动完成"

echo ""
echo "步骤 5: 等待服务就绪..."
sleep 15

echo ""
echo "步骤 6: 检查服务状态..."
docker-compose ps

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "服务信息:"
echo "  Milvus API:  localhost:19530"
echo "  Attu 管理界面:  http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "下一步:"
echo "  1. 配置防火墙开放端口 3000 和 19530"
echo "  2. 可选：配置 Nginx 反向代理（参考 deploy/nginx-attu.conf）"
echo ""
echo "查看日志:"
echo "  cd $MILVUS_DIR && docker-compose logs -f"
echo ""

