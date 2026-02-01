#!/bin/bash
# 阿里云服务器上直接执行的 Docker 部署脚本
# 使用方法: 在服务器上执行: bash deploy-docker-aliyun-server.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "🚀 阿里云 Docker 部署脚本"
echo "时间: $TIMESTAMP"
echo "=========================================="
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "⚠️  请使用 sudo 运行此脚本"
    echo "   示例: sudo bash deploy-docker-aliyun-server.sh"
    exit 1
fi

# 步骤 1: 检查并安装 Docker
echo ">>> 步骤 1: 检查 Docker 环境..."
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，开始安装..."
    # 安装 Docker
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io
    
    # 配置镜像加速
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF
    
    systemctl daemon-reload
    systemctl start docker
    systemctl enable docker
    echo "✓ Docker 安装完成"
else
    echo "✓ Docker 已安装: $(docker --version)"
fi

# 检查 Docker 服务状态
if ! systemctl is-active --quiet docker; then
    systemctl start docker
    systemctl enable docker
fi
echo "✓ Docker 服务运行中"
echo ""

# 步骤 2: 检查并安装 Docker Compose
echo ">>> 步骤 2: 检查 Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未安装，开始安装..."
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✓ Docker Compose 安装完成"
else
    echo "✓ Docker Compose 已安装: $(docker-compose --version)"
fi
echo ""

# 步骤 3: 检查项目目录
echo ">>> 步骤 3: 检查项目目录..."
if [ ! -d "$DEPLOY_PATH" ]; then
    echo "❌ 项目目录不存在: $DEPLOY_PATH"
    echo "   请先同步代码到服务器"
    exit 1
fi
cd "$DEPLOY_PATH"
echo "✓ 项目目录: $DEPLOY_PATH"
echo ""

# 步骤 4: 拉取最新代码
echo ">>> 步骤 4: 拉取最新代码..."
if [ -d ".git" ]; then
    git pull || echo "⚠️  Git pull 失败，继续使用现有代码"
else
    echo "⚠️  不是 Git 仓库，跳过代码更新"
fi
echo ""

# 步骤 5: 创建必要的目录
echo ">>> 步骤 5: 创建必要的目录..."
mkdir -p data/article-covers
mkdir -p data/book-covers
chmod -R 755 data
echo "✓ 数据目录已创建"
echo ""

# 步骤 6: 配置环境变量
echo ">>> 步骤 6: 配置环境变量..."
if [ ! -f .env ]; then
    echo "创建 .env 文件..."
    cat > .env <<EOF
# 数据库配置
DATABASE_URL=sqlite:////app/data/products.db

# 允许的源（根据实际域名/IP修改）
ALLOWED_ORIGINS=https://linchuan.tech,http://linchuan.tech,https://47.112.29.212,http://47.112.29.212

# 后端配置
HOST=0.0.0.0
PORT=8000

# JWT 密钥（生产环境请修改）
SECRET_KEY=your-secret-key-change-in-production-$(date +%s)
EOF
    echo "✓ .env 文件已创建"
else
    echo "✓ .env 文件已存在"
fi
echo ""

# 步骤 7: 停止旧容器（如果存在）
echo ">>> 步骤 7: 停止旧容器..."
if [ -f docker-compose.yml ]; then
    docker-compose down 2>/dev/null || true
    echo "✓ 旧容器已停止"
else
    echo "❌ docker-compose.yml 不存在"
    exit 1
fi
echo ""

# 步骤 8: 构建并启动 Docker 服务
echo ">>> 步骤 8: 构建并启动 Docker 服务..."
echo "开始构建镜像..."
docker-compose build

echo "启动服务..."
docker-compose up -d

echo "✓ Docker 服务已启动"
echo ""

# 步骤 9: 等待服务就绪
echo ">>> 步骤 9: 等待服务就绪..."
sleep 15

# 检查服务状态
echo "检查服务状态..."
docker-compose ps

echo ""
echo "等待后端服务启动..."
for i in {1..30}; do
    if curl -f http://localhost:8000/api/health &>/dev/null; then
        echo "✓ 后端服务已就绪"
        break
    fi
    echo "  等待中... ($i/30)"
    sleep 2
done

if ! curl -f http://localhost:8000/api/health &>/dev/null; then
    echo "⚠️  后端服务可能未完全启动，请检查日志: docker-compose logs backend"
fi
echo ""

# 步骤 10: 初始化数据库（如果需要）
echo ">>> 步骤 10: 初始化数据库..."
if [ -f backend/init_db.py ]; then
    echo "执行数据库初始化..."
    docker-compose exec -T backend python init_db.py || {
        echo "⚠️  数据库初始化失败，可能已存在数据"
    }
    echo "✓ 数据库初始化完成"
else
    echo "⚠️  init_db.py 不存在，跳过数据库初始化"
fi
echo ""

echo "=========================================="
echo "✅ 部署完成！"
echo "=========================================="
echo ""
echo "📋 服务访问地址:"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "   - 前端应用: http://${SERVER_IP}:5173"
echo "   - 后端 API: http://${SERVER_IP}:8000"
echo "   - API 文档: http://${SERVER_IP}:8000/docs"
echo ""
echo "📋 常用命令:"
echo "   - 查看日志: docker-compose logs -f"
echo "   - 查看状态: docker-compose ps"
echo "   - 停止服务: docker-compose down"
echo "   - 重启服务: docker-compose restart"
echo ""

