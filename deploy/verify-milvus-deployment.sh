#!/bin/bash
# 验证 Milvus 和 Attu 部署

set -e

echo "=========================================="
echo "验证 Milvus 和 Attu 部署"
echo "=========================================="
echo ""

MILVUS_DIR="/opt/milvus"
SERVER_IP=$(hostname -I | awk '{print $1}' || echo "localhost")

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查 Docker
echo "1. 检查 Docker..."
if command -v docker &> /dev/null; then
    echo -e "   ${GREEN}✓ Docker 已安装${NC}"
    docker --version
else
    echo -e "   ${RED}✗ Docker 未安装${NC}"
fi
echo ""

# 检查 Docker Compose
echo "2. 检查 Docker Compose..."
if command -v docker-compose &> /dev/null; then
    echo -e "   ${GREEN}✓ Docker Compose 已安装${NC}"
    docker-compose --version
else
    echo -e "   ${RED}✗ Docker Compose 未安装${NC}"
fi
echo ""

# 检查服务目录
echo "3. 检查部署目录..."
if [ -d "$MILVUS_DIR" ]; then
    echo -e "   ${GREEN}✓ 部署目录存在: $MILVUS_DIR${NC}"
else
    echo -e "   ${RED}✗ 部署目录不存在: $MILVUS_DIR${NC}"
fi
echo ""

# 检查 Docker Compose 文件
echo "4. 检查 Docker Compose 配置文件..."
if [ -f "$MILVUS_DIR/docker-compose.yml" ]; then
    echo -e "   ${GREEN}✓ 配置文件存在${NC}"
else
    echo -e "   ${RED}✗ 配置文件不存在${NC}"
fi
echo ""

# 检查容器状态
echo "5. 检查容器状态..."
if [ -f "$MILVUS_DIR/docker-compose.yml" ]; then
    cd $MILVUS_DIR
    echo "   容器列表:"
    docker-compose ps
    echo ""
    
    # 检查各个服务
    SERVICES=("etcd" "minio" "standalone" "attu")
    for SERVICE in "${SERVICES[@]}"; do
        if docker-compose ps | grep -q "$SERVICE.*Up"; then
            echo -e "   ${GREEN}✓ $SERVICE 运行中${NC}"
        else
            echo -e "   ${RED}✗ $SERVICE 未运行${NC}"
        fi
    done
else
    echo -e "   ${YELLOW}⚠ 无法检查容器状态（配置文件不存在）${NC}"
fi
echo ""

# 检查端口监听
echo "6. 检查端口监听..."
PORTS=(19530 3000 9000 9001)
PORT_NAMES=("Milvus API" "Attu" "MinIO API" "MinIO Console")
for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${PORT_NAMES[$i]}
    if netstat -tlnp 2>/dev/null | grep -q ":$PORT " || ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
        echo -e "   ${GREEN}✓ 端口 $PORT ($NAME) 正在监听${NC}"
    else
        echo -e "   ${RED}✗ 端口 $PORT ($NAME) 未监听${NC}"
    fi
done
echo ""

# 测试 Milvus 连接
echo "7. 测试 Milvus 连接..."
if command -v curl &> /dev/null; then
    if curl -s http://localhost:9091/healthz > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓ Milvus 健康检查通过${NC}"
    else
        echo -e "   ${YELLOW}⚠ Milvus 健康检查失败（可能还在启动中）${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ curl 未安装，跳过健康检查${NC}"
fi
echo ""

# 测试 Attu 连接
echo "8. 测试 Attu 连接..."
if command -v curl &> /dev/null; then
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo -e "   ${GREEN}✓ Attu 服务可访问${NC}"
    else
        echo -e "   ${YELLOW}⚠ Attu 服务不可访问（可能还在启动中）${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ curl 未安装，跳过连接测试${NC}"
fi
echo ""

# 显示访问信息
echo "=========================================="
echo "访问信息"
echo "=========================================="
echo ""
echo "  Milvus API:        localhost:19530"
echo "  Attu 管理界面:     http://$SERVER_IP:3000"
echo "  MinIO 控制台:      http://$SERVER_IP:9001"
echo ""
echo "首次访问 Attu 时，Milvus 地址填写:"
echo "  - 容器内: milvus-standalone:19530"
echo "  - 外部:   localhost:19530 或 $SERVER_IP:19530"
echo ""

# 检查防火墙
echo "9. 检查防火墙配置..."
if command -v firewall-cmd &> /dev/null; then
    OPEN_PORTS=$(sudo firewall-cmd --list-ports 2>/dev/null || echo "")
    if [ -n "$OPEN_PORTS" ]; then
        echo "   已开放的端口: $OPEN_PORTS"
        for PORT in "${PORTS[@]}"; do
            if echo "$OPEN_PORTS" | grep -q "$PORT"; then
                echo -e "   ${GREEN}✓ 端口 $PORT 已开放${NC}"
            else
                echo -e "   ${YELLOW}⚠ 端口 $PORT 可能未开放${NC}"
            fi
        done
    else
        echo -e "   ${YELLOW}⚠ 无法获取防火墙信息${NC}"
    fi
else
    echo -e "   ${YELLOW}⚠ 未检测到 firewalld，请手动检查防火墙${NC}"
fi
echo ""

echo "=========================================="
echo "验证完成"
echo "=========================================="
echo ""
echo "如果发现问题，请检查:"
echo "  1. 服务日志: cd $MILVUS_DIR && docker-compose logs -f"
echo "  2. 防火墙配置: 运行 deploy/configure-firewall.sh"
echo "  3. 阿里云安全组: 确保已开放端口 3000 和 19530"
echo ""

