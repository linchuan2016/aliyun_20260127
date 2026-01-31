#!/bin/bash
# 配置防火墙开放 Milvus 和 Attu 端口

set -e

echo "=========================================="
echo "配置防火墙（开放 Milvus 和 Attu 端口）"
echo "=========================================="
echo ""

PORTS=(19530 3000 9000 9001)
PORT_NAMES=("Milvus API" "Attu 管理界面" "MinIO API" "MinIO 控制台")

# 检查 firewalld
if command -v firewall-cmd &> /dev/null; then
    echo "检测到 firewalld，使用 firewalld 配置..."
    for i in "${!PORTS[@]}"; do
        PORT=${PORTS[$i]}
        NAME=${PORT_NAMES[$i]}
        echo "开放端口 $PORT ($NAME)..."
        sudo firewall-cmd --permanent --add-port=${PORT}/tcp 2>/dev/null || true
    done
    sudo firewall-cmd --reload
    echo "✓ 防火墙配置完成"
    echo ""
    echo "当前开放的端口:"
    sudo firewall-cmd --list-ports
    exit 0
fi

# 检查 iptables
if command -v iptables &> /dev/null; then
    echo "检测到 iptables，使用 iptables 配置..."
    for i in "${!PORTS[@]}"; do
        PORT=${PORTS[$i]}
        NAME=${PORT_NAMES[$i]}
        echo "开放端口 $PORT ($NAME)..."
        sudo iptables -A INPUT -p tcp --dport $PORT -j ACCEPT 2>/dev/null || true
    done
    echo "✓ 防火墙规则添加完成"
    echo ""
    echo "注意: 如果使用 iptables，请确保规则已保存:"
    echo "  CentOS/RHEL: sudo service iptables save"
    echo "  Ubuntu/Debian: sudo iptables-save > /etc/iptables/rules.v4"
    exit 0
fi

echo "未检测到防火墙工具，请手动配置防火墙"
echo ""
echo "需要开放的端口:"
for i in "${!PORTS[@]}"; do
    PORT=${PORTS[$i]}
    NAME=${PORT_NAMES[$i]}
    echo "  $PORT/tcp - $NAME"
done
echo ""
echo "阿里云安全组配置:"
echo "  登录阿里云控制台 -> ECS -> 安全组 -> 配置规则"
echo "  添加入方向规则，开放上述端口"

