#!/bin/bash
# 安全地检查 Milvus 服务状态（自动处理权限问题）

echo "=========================================="
echo "检查 Milvus 和 Attu 服务状态"
echo "=========================================="
echo ""

# 检测是否需要 sudo
if docker ps &>/dev/null; then
    DOCKER_CMD="docker"
    echo "使用普通用户权限"
else
    DOCKER_CMD="sudo docker"
    echo "使用 sudo 权限"
fi
echo ""

# 检查容器
echo "容器状态:"
echo "----------------------------------------"
$DOCKER_CMD ps --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || \
$DOCKER_CMD ps -a --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# 检查各个服务
SERVICES=("milvus-etcd" "milvus-minio" "milvus-standalone" "milvus-attu")

echo "详细状态:"
echo "----------------------------------------"
for SERVICE in "${SERVICES[@]}"; do
    if $DOCKER_CMD ps --format "{{.Names}}" 2>/dev/null | grep -q "^${SERVICE}$"; then
        STATUS=$($DOCKER_CMD inspect --format='{{.State.Status}}' "$SERVICE" 2>/dev/null)
        HEALTH=$($DOCKER_CMD inspect --format='{{.State.Health.Status}}' "$SERVICE" 2>/dev/null || echo "no-healthcheck")
        echo "✓ $SERVICE: $STATUS (health: $HEALTH)"
    else
        echo "✗ $SERVICE: 未运行"
    fi
done
echo ""

# 检查端口（使用 sudo，因为 netstat 可能需要权限）
echo "端口监听状态:"
echo "----------------------------------------"
PORTS=(19530 3000 9000 9001)
PORT_NAMES=("Milvus API" "Attu" "MinIO API" "MinIO Console")

for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${PORT_NAMES[$i]}
    if sudo netstat -tlnp 2>/dev/null | grep -q ":$PORT " || sudo ss -tlnp 2>/dev/null | grep -q ":$PORT "; then
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

# 检查服务日志（最后几行）
echo "服务日志（最后 5 行）:"
echo "----------------------------------------"
for SERVICE in "${SERVICES[@]}"; do
    echo ""
    echo "$SERVICE:"
    $DOCKER_CMD logs --tail 5 "$SERVICE" 2>/dev/null || echo "  无法获取日志"
done
echo ""

