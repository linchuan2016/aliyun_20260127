#!/bin/bash
# Milvus 和 Attu 部署脚本
# 在阿里云服务器上执行此脚本

set -e

echo "=========================================="
echo "开始部署 Milvus 和 Attu"
echo "=========================================="
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "错误: Docker 未安装，请先安装 Docker"
    echo "安装命令: curl -fsSL https://get.docker.com | bash"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "错误: Docker Compose 未安装，请先安装 Docker Compose"
    echo "安装命令: sudo curl -L \"https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
    exit 1
fi

# 设置部署目录
MILVUS_DIR="/opt/milvus"
COMPOSE_FILE="$MILVUS_DIR/docker-compose.yml"

echo "步骤 1: 创建部署目录..."
sudo mkdir -p $MILVUS_DIR
sudo mkdir -p $MILVUS_DIR/volumes/{etcd,minio,milvus}
echo "✓ 目录创建完成"
echo ""

echo "步骤 2: 复制 docker-compose.yml..."
# 如果是从项目目录运行，复制文件
if [ -f "deploy/milvus-docker-compose.yml" ]; then
    sudo cp deploy/milvus-docker-compose.yml $COMPOSE_FILE
elif [ -f "milvus-docker-compose.yml" ]; then
    sudo cp milvus-docker-compose.yml $COMPOSE_FILE
else
    echo "警告: 未找到 docker-compose.yml 文件，请手动复制到 $COMPOSE_FILE"
fi
echo "✓ 文件复制完成"
echo ""

echo "步骤 3: 设置目录权限..."
sudo chown -R $USER:$USER $MILVUS_DIR
sudo chmod -R 755 $MILVUS_DIR
echo "✓ 权限设置完成"
echo ""

echo "步骤 4: 启动 Milvus 和 Attu 服务..."
cd $MILVUS_DIR
docker-compose down 2>/dev/null || true
docker-compose up -d
echo "✓ 服务启动完成"
echo ""

echo "步骤 5: 等待服务就绪..."
sleep 10

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "服务状态:"
docker-compose ps
echo ""
echo "访问地址:"
echo "  Milvus API:  localhost:19530"
echo "  Attu 管理界面:  http://YOUR_SERVER_IP:3000"
echo ""
echo "检查服务日志:"
echo "  docker-compose logs -f"
echo ""
echo "停止服务:"
echo "  cd $MILVUS_DIR && docker-compose down"
echo ""
echo "重启服务:"
echo "  cd $MILVUS_DIR && docker-compose restart"
echo ""

