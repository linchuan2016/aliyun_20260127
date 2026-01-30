#!/bin/bash
# Milvus 和 Attu 完整部署脚本（阿里云专用）
# 此脚本会自动完成所有部署步骤

set -e

echo "=========================================="
echo "Milvus 和 Attu 完整部署脚本（阿里云）"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}提示: 建议使用 sudo 运行此脚本${NC}"
    echo ""
fi

# 设置变量
MILVUS_DIR="/opt/milvus"
PROJECT_DIR="/var/www/my-fullstack-app"
COMPOSE_FILE="$MILVUS_DIR/docker-compose.yml"

# 步骤 1: 检查并安装 Docker
echo -e "${GREEN}步骤 1: 检查 Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，开始安装..."
    
    # 检查内存
    AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}' 2>/dev/null || echo "1000")
    echo "可用内存: ${AVAIL_MEM}MB"
    
    if [ "$AVAIL_MEM" -lt 500 ] && [ -f "$PROJECT_DIR/deploy/install-docker-aliyun-low-memory.sh" ]; then
        echo -e "${YELLOW}内存较低，使用低内存优化安装脚本...${NC}"
        chmod +x "$PROJECT_DIR/deploy/install-docker-aliyun-low-memory.sh"
        sudo "$PROJECT_DIR/deploy/install-docker-aliyun-low-memory.sh"
    elif [ -f "$PROJECT_DIR/deploy/install-docker-aliyun.sh" ]; then
        chmod +x "$PROJECT_DIR/deploy/install-docker-aliyun.sh"
        sudo "$PROJECT_DIR/deploy/install-docker-aliyun.sh"
    else
        echo "使用 yum 安装 Docker..."
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2
        sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        
        # 配置 Docker 镜像加速
        sudo mkdir -p /etc/docker
        sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF
        
        sudo systemctl daemon-reload
        sudo systemctl start docker
        sudo systemctl enable docker
    fi
    echo -e "${GREEN}✓ Docker 安装完成${NC}"
else
    echo -e "${GREEN}✓ Docker 已安装${NC}"
    docker --version
fi
echo ""

# 步骤 2: 检查并安装 Docker Compose
echo -e "${GREEN}步骤 2: 检查 Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未安装，开始安装..."
    if [ -f "$PROJECT_DIR/deploy/install-docker-compose.sh" ]; then
        chmod +x "$PROJECT_DIR/deploy/install-docker-compose.sh"
        sudo "$PROJECT_DIR/deploy/install-docker-compose.sh"
    else
        COMPOSE_VERSION="2.20.0"
        ARCH=$(uname -m)
        DOWNLOAD_URL="https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"
        
        echo "下载 Docker Compose..."
        sudo curl -L "$DOWNLOAD_URL" -o /usr/local/bin/docker-compose || \
        sudo wget -O /usr/local/bin/docker-compose "$DOWNLOAD_URL"
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
    fi
    echo -e "${GREEN}✓ Docker Compose 安装完成${NC}"
else
    echo -e "${GREEN}✓ Docker Compose 已安装${NC}"
    docker-compose --version
fi
echo ""

# 步骤 3: 配置防火墙
echo -e "${GREEN}步骤 3: 配置防火墙...${NC}"
if command -v firewall-cmd &> /dev/null; then
    echo "配置 firewalld..."
    sudo firewall-cmd --permanent --add-port=19530/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --add-port=3000/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --add-port=9000/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --add-port=9001/tcp 2>/dev/null || true
    sudo firewall-cmd --reload 2>/dev/null || true
    echo -e "${GREEN}✓ 防火墙配置完成${NC}"
elif command -v iptables &> /dev/null; then
    echo "配置 iptables..."
    sudo iptables -A INPUT -p tcp --dport 19530 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 9000 -j ACCEPT 2>/dev/null || true
    sudo iptables -A INPUT -p tcp --dport 9001 -j ACCEPT 2>/dev/null || true
    echo -e "${GREEN}✓ 防火墙配置完成${NC}"
else
    echo -e "${YELLOW}⚠ 未检测到防火墙工具，请手动配置防火墙${NC}"
fi
echo ""

# 步骤 4: 创建部署目录
echo -e "${GREEN}步骤 4: 创建部署目录...${NC}"
sudo mkdir -p $MILVUS_DIR/volumes/{etcd,minio,milvus}
echo -e "${GREEN}✓ 目录创建完成${NC}"
echo ""

# 步骤 5: 复制配置文件
echo -e "${GREEN}步骤 5: 复制配置文件...${NC}"
if [ -f "$PROJECT_DIR/deploy/milvus-docker-compose.yml" ]; then
    sudo cp "$PROJECT_DIR/deploy/milvus-docker-compose.yml" "$COMPOSE_FILE"
    echo -e "${GREEN}✓ 配置文件复制完成${NC}"
elif [ -f "deploy/milvus-docker-compose.yml" ]; then
    sudo cp "deploy/milvus-docker-compose.yml" "$COMPOSE_FILE"
    echo -e "${GREEN}✓ 配置文件复制完成${NC}"
else
    echo -e "${RED}错误: 未找到 docker-compose.yml 文件${NC}"
    echo "请确保项目代码已同步到服务器"
    exit 1
fi
echo ""

# 步骤 6: 设置权限
echo -e "${GREEN}步骤 6: 设置目录权限...${NC}"
sudo chown -R $USER:$USER $MILVUS_DIR 2>/dev/null || sudo chown -R $(whoami):$(whoami) $MILVUS_DIR
sudo chmod -R 755 $MILVUS_DIR
echo -e "${GREEN}✓ 权限设置完成${NC}"
echo ""

# 步骤 7: 停止旧服务（如果存在）
echo -e "${GREEN}步骤 7: 停止旧服务（如果存在）...${NC}"
cd $MILVUS_DIR
docker-compose down 2>/dev/null || true
echo -e "${GREEN}✓ 清理完成${NC}"
echo ""

# 步骤 8: 启动服务
echo -e "${GREEN}步骤 8: 启动 Milvus 和 Attu 服务...${NC}"
cd $MILVUS_DIR
docker-compose up -d
echo -e "${GREEN}✓ 服务启动完成${NC}"
echo ""

# 步骤 9: 等待服务就绪
echo -e "${GREEN}步骤 9: 等待服务就绪...${NC}"
echo "等待 20 秒让服务完全启动..."
sleep 20
echo -e "${GREEN}✓ 等待完成${NC}"
echo ""

# 步骤 10: 检查服务状态
echo -e "${GREEN}步骤 10: 检查服务状态...${NC}"
cd $MILVUS_DIR
docker-compose ps
echo ""

# 获取服务器 IP
SERVER_IP=$(hostname -I | awk '{print $1}' || echo "YOUR_SERVER_IP")

echo ""
echo "=========================================="
echo -e "${GREEN}部署完成！${NC}"
echo "=========================================="
echo ""
echo "服务信息:"
echo "  Milvus API:        localhost:19530"
echo "  Attu 管理界面:     http://$SERVER_IP:3000"
echo "  MinIO 控制台:      http://$SERVER_IP:9001"
echo ""
echo "常用命令:"
echo "  查看服务状态:      cd $MILVUS_DIR && docker-compose ps"
echo "  查看服务日志:      cd $MILVUS_DIR && docker-compose logs -f"
echo "  重启服务:          cd $MILVUS_DIR && docker-compose restart"
echo "  停止服务:          cd $MILVUS_DIR && docker-compose down"
echo ""
echo "首次访问 Attu:"
echo "  1. 打开浏览器访问: http://$SERVER_IP:3000"
echo "  2. Milvus 地址填写: milvus-standalone:19530 (容器内) 或 localhost:19530 (外部)"
echo "  3. 用户名和密码留空（默认配置）"
echo ""
echo -e "${YELLOW}注意: 如果无法访问，请检查:${NC}"
echo "  1. 防火墙是否已开放端口 3000 和 19530"
echo "  2. 阿里云安全组是否已开放相应端口"
echo "  3. 服务是否正常运行: docker-compose ps"
echo ""

