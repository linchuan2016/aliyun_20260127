#!/bin/bash
# 检查 Milvus 服务状态（避免使用 docker-compose ps）

echo "=========================================="
echo "检查 Milvus 和 Attu 服务状态"
echo "=========================================="
echo ""

# 检查容器
echo "容器状态:"
echo "----------------------------------------"
docker ps --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || docker ps -a --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 检查各个服务
SERVICES=("milvus-etcd" "milvus-minio" "milvus-standalone" "milvus-attu")

echo "详细状态:"
echo "----------------------------------------"
for SERVICE in "${SERVICES[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${SERVICE}$"; then
        STATUS=$(docker inspect --format='{{.State.Status}}' "$SERVICE" 2>/dev/null)
        HEALTH=$(docker inspect --format='{{.State.Health.Status}}' "$SERVICE" 2>/dev/null || echo "no-healthcheck")
        echo "✓ $SERVICE: $STATUS (health: $HEALTH)"
    else
        echo "✗ $SERVICE: 未运行"
    fi
done
echo ""

# 检查端口
echo "端口监听状态:"
echo "----------------------------------------"
PORTS=(19530 3000 9000 9001)
PORT_NAMES=("Milvus API" "Attu" "MinIO API" "MinIO Console")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${PORT_NAMES[$i]}
    if netstat -tlnp 2>/dev/null | grep -q ":$PORT " || ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
        echo "✓ 端口 $PORT ($NAME): 正在监听"
    else
        echo "✗ 端口 $PORT ($NAME): 未监听"
    fi
done
echo ""

# 获取服务器 IP
SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "YOUR_SERVER_IP")

echo "访问地址:"
echo "----------------------------------------"
echo "  Milvus API:        $SERVER_IP:19530"
echo "  Attu 管理界面:     http://$SERVER_IP:3000"
echo "  MinIO 控制台:      http://$SERVER_IP:9001"
echo ""

