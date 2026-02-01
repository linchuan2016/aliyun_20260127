#!/bin/bash
# 阿里云 Docker Compose 完整部署脚本
# 使用方法: 在阿里云服务器上执行: bash scripts/deploy/deploy-docker-aliyun.sh

set -e  # 遇到错误立即退出

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
    echo "   示例: sudo bash scripts/deploy/deploy-docker-aliyun.sh"
    exit 1
fi

# 步骤 1: 检查并安装 Docker
echo ">>> 步骤 1: 检查 Docker 环境..."
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，开始安装..."
    bash "$DEPLOY_PATH/scripts/deploy/install-docker-aliyun.sh"
else
    echo "✓ Docker 已安装: $(docker --version)"
fi

# 检查 Docker 服务状态
if ! systemctl is-active --quiet docker; then
    echo "启动 Docker 服务..."
    systemctl start docker
    systemctl enable docker
fi
echo "✓ Docker 服务运行中"
echo ""

# 步骤 2: 检查并安装 Docker Compose
echo ">>> 步骤 2: 检查 Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未安装，开始安装..."
    bash "$DEPLOY_PATH/scripts/deploy/install-docker-compose.sh"
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

# 步骤 4: 创建必要的目录
echo ">>> 步骤 4: 创建必要的目录..."
mkdir -p data/article-covers
mkdir -p data/book-covers
chmod -R 755 data
echo "✓ 数据目录已创建"
echo ""

# 步骤 5: 配置环境变量
echo ">>> 步骤 5: 配置环境变量..."
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

# 步骤 6: 停止旧容器（如果存在）
echo ">>> 步骤 6: 停止旧容器..."
cd "$DEPLOY_PATH"
if [ -f docker-compose.yml ]; then
    docker-compose down 2>/dev/null || true
    echo "✓ 旧容器已停止"
else
    echo "⚠️  docker-compose.yml 不存在"
fi
echo ""

# 步骤 7: 构建并启动 Docker 服务
echo ">>> 步骤 7: 构建并启动 Docker 服务..."
cd "$DEPLOY_PATH"

# 检查内存
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
echo "系统总内存: ${TOTAL_MEM}MB"

if [ "$TOTAL_MEM" -lt 2048 ]; then
    echo "⚠️  警告: 系统内存小于 2GB，Milvus 可能无法正常运行"
    echo "   建议至少 4GB 内存用于完整部署"
    echo ""
    read -p "是否继续部署（跳过 Milvus 相关服务）? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "使用精简版配置（不包含 Milvus）..."
        # 可以创建一个精简版的 docker-compose.yml
    else
        echo "部署已取消"
        exit 1
    fi
fi

echo "开始构建镜像..."
docker-compose build --no-cache

echo "启动服务..."
docker-compose up -d

echo "✓ Docker 服务已启动"
echo ""

# 步骤 8: 等待服务就绪
echo ">>> 步骤 8: 等待服务就绪..."
sleep 10

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

# 步骤 9: 初始化数据库（如果需要）
echo ">>> 步骤 9: 初始化数据库..."
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

# 步骤 10: 配置 Nginx（如果需要外部访问）
echo ">>> 步骤 10: 配置 Nginx（可选）..."
if command -v nginx &> /dev/null; then
    echo "检测到系统已安装 Nginx"
    read -p "是否配置 Nginx 反向代理? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "配置 Nginx..."
        
        # 备份现有配置
        if [ -f /etc/nginx/conf.d/my-fullstack-app.conf ]; then
            cp /etc/nginx/conf.d/my-fullstack-app.conf /etc/nginx/conf.d/my-fullstack-app.conf.backup.$TIMESTAMP
        fi
        
        # 创建 Nginx 配置
        cat > /etc/nginx/conf.d/my-fullstack-app.conf <<'NGINX_EOF'
# 上游后端服务器（Docker 容器）
upstream docker_backend {
    server 127.0.0.1:8000;
}

upstream docker_frontend {
    server 127.0.0.1:5173;
}

upstream docker_attu {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name _;  # 替换为你的域名或IP

    # 静态文件代理到后端（图片等）
    location ^~ /data/ {
        proxy_pass http://docker_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Attu 访问验证（内部 location）
    location = /api/auth/verify-attu {
        internal;
        proxy_pass http://docker_backend/api/auth/verify-attu;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header Cookie $http_cookie;
        proxy_set_header Authorization $http_authorization;
    }

    # Attu 管理界面代理
    location ^~ /attu/ {
        auth_request /api/auth/verify-attu;
        auth_request_set $auth_status $upstream_status;
        error_page 401 = @attu_unauthorized;
        
        rewrite ^/attu/?(.*)$ /$1 break;
        proxy_pass http://docker_attu;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        proxy_buffering off;
    }
    
    location @attu_unauthorized {
        return 302 /admin/login?redirect=/attu;
    }

    # 后端 API 代理
    location /api/ {
        proxy_pass http://docker_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;
        
        if ($request_method = OPTIONS) {
            return 204;
        }
    }

    # 前端应用代理
    location / {
        proxy_pass http://docker_frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket 支持（如果需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX_EOF

        # 测试 Nginx 配置
        if nginx -t; then
            systemctl reload nginx
            echo "✓ Nginx 配置已更新并重载"
        else
            echo "❌ Nginx 配置有误，请检查"
        fi
    fi
else
    echo "⚠️  系统未安装 Nginx，跳过配置"
    echo "   如需外部访问，请安装 Nginx 或使用 Docker 容器的端口映射"
fi
echo ""

# 步骤 11: 配置防火墙（如果需要）
echo ">>> 步骤 11: 配置防火墙..."
if command -v firewall-cmd &> /dev/null; then
    echo "配置防火墙规则..."
    firewall-cmd --permanent --add-port=80/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=443/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=8000/tcp 2>/dev/null || true
    firewall-cmd --permanent --add-port=5173/tcp 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    echo "✓ 防火墙规则已配置"
else
    echo "⚠️  未检测到 firewalld，请手动配置防火墙"
fi
echo ""

# 步骤 12: 验证部署
echo ">>> 步骤 12: 验证部署..."
echo "检查服务状态..."
docker-compose ps

echo ""
echo "测试后端 API..."
if curl -f http://localhost:8000/api/health &>/dev/null; then
    echo "✓ 后端服务正常"
else
    echo "❌ 后端服务异常，请检查日志: docker-compose logs backend"
fi

echo ""
echo "测试前端服务..."
if curl -f http://localhost:5173 &>/dev/null; then
    echo "✓ 前端服务正常"
else
    echo "❌ 前端服务异常，请检查日志: docker-compose logs frontend"
fi

echo ""
echo "=========================================="
echo "✅ 部署完成！"
echo "=========================================="
echo ""
echo "📋 服务访问地址:"
echo "   - 前端应用: http://$(hostname -I | awk '{print $1}'):5173"
echo "   - 后端 API: http://$(hostname -I | awk '{print $1}'):8000"
echo "   - API 文档: http://$(hostname -I | awk '{print $1}'):8000/docs"
echo ""
echo "📋 常用命令:"
echo "   - 查看日志: docker-compose logs -f"
echo "   - 查看状态: docker-compose ps"
echo "   - 停止服务: docker-compose down"
echo "   - 重启服务: docker-compose restart"
echo "   - 更新代码: git pull && docker-compose up -d --build"
echo ""
echo "⚠️  注意事项:"
echo "   1. 确保 .env 文件中的 ALLOWED_ORIGINS 包含实际访问域名"
echo "   2. 生产环境请修改 SECRET_KEY"
echo "   3. 建议配置 SSL 证书（HTTPS）"
echo ""

