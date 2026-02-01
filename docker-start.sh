#!/bin/bash
# Docker 启动脚本 (Linux/Mac)
# 功能：检查 Docker 环境，构建并启动服务

set -e

echo ""
echo "=========================================="
echo "Docker 部署脚本"
echo "=========================================="
echo ""

# 检查 Docker 是否安装
echo "1. 检查 Docker 环境..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "   ✓ Docker 已安装: $DOCKER_VERSION"
else
    echo "   ✗ Docker 未安装"
    echo "   请先安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# 检查 Docker 是否运行
if docker ps &> /dev/null; then
    echo "   ✓ Docker 服务正在运行"
else
    echo "   ✗ Docker 服务未运行"
    echo "   请启动 Docker 服务"
    exit 1
fi

echo ""

# 检查 docker-compose
echo "2. 检查 docker-compose..."
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    if command -v docker-compose &> /dev/null; then
        COMPOSE_VERSION=$(docker-compose --version)
    else
        COMPOSE_VERSION=$(docker compose version)
    fi
    echo "   ✓ docker-compose 已安装: $COMPOSE_VERSION"
else
    echo "   ✗ docker-compose 未安装"
    exit 1
fi

echo ""

# 检查 .env 文件
echo "3. 检查环境变量配置..."
if [ -f ".env" ]; then
    echo "   ✓ .env 文件存在"
else
    echo "   ⚠ .env 文件不存在，从 env.example 创建..."
    if [ -f "env.example" ]; then
        cp env.example .env
        echo "   ✓ 已创建 .env 文件，请根据需要修改配置"
    else
        echo "   ⚠ env.example 文件不存在，将使用默认配置"
    fi
fi

echo ""

# 确保数据目录存在
echo "4. 检查数据目录..."
if [ ! -d "data" ]; then
    mkdir -p data/article-covers data/book-covers
    echo "   ✓ 已创建数据目录"
else
    echo "   ✓ 数据目录存在"
fi

echo ""

# 构建并启动服务
echo "5. 构建 Docker 镜像..."
if command -v docker-compose &> /dev/null; then
    docker-compose build
else
    docker compose build
fi

if [ $? -ne 0 ]; then
    echo "   ✗ 构建失败"
    exit 1
fi
echo "   ✓ 构建成功"
echo ""

echo "6. 启动服务..."
if command -v docker-compose &> /dev/null; then
    docker-compose up -d
else
    docker compose up -d
fi

if [ $? -ne 0 ]; then
    echo "   ✗ 启动失败"
    exit 1
fi
echo "   ✓ 服务已启动"
echo ""

# 等待服务就绪
echo "7. 等待服务就绪..."
sleep 5

# 检查服务状态
echo ""
echo "8. 检查服务状态..."
if command -v docker-compose &> /dev/null; then
    docker-compose ps
else
    docker compose ps
fi
echo ""

# 测试后端健康检查
echo "9. 测试后端服务..."
sleep 3
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/api/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "   ✓ 后端服务正常 (HTTP $HTTP_CODE)"
    curl -s http://localhost:8000/api/health
    echo ""
else
    echo "   ⚠ 后端服务可能尚未完全启动，请稍后重试 (HTTP $HTTP_CODE)"
fi

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "服务地址:"
echo "  后端 API: http://localhost:8000"
echo "  前端应用: http://localhost:5173"
echo "  API 文档: http://localhost:8000/docs"
echo ""
echo "常用命令:"
echo "  查看日志: docker-compose logs -f"
echo "  停止服务: docker-compose down"
echo "  重启服务: docker-compose restart"
echo "  查看状态: docker-compose ps"
echo ""

