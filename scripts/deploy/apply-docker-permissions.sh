#!/bin/bash
# 应用 Docker 权限（无需密码的替代方案）

echo "=========================================="
echo "应用 Docker 权限"
echo "=========================================="
echo ""

CURRENT_USER=$(whoami)
echo "当前用户: $CURRENT_USER"
echo ""

# 检查用户是否在 docker 组中
if groups | grep -q docker; then
    echo "✓ 用户已在 docker 组中"
    echo ""
    echo "如果仍然无法使用 docker 命令，请尝试以下方法："
    echo ""
    echo "方法 1: 重新登录 SSH（推荐，永久生效）"
    echo "  退出当前 SSH 会话，重新登录"
    echo ""
    echo "方法 2: 使用 sudo（临时方案）"
    echo "  sudo docker ps"
    echo ""
    echo "方法 3: 使用 sg 命令（如果可用）"
    echo "  sg docker -c 'docker ps'"
    echo ""
else
    echo "用户尚未添加到 docker 组"
    echo "请先运行: sudo ./scripts/deploy/fix-docker-permissions.sh"
fi

echo ""
echo "测试 Docker 权限:"
echo "----------------------------------------"
if docker ps &>/dev/null; then
    echo "✓ Docker 权限正常"
    docker ps --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  无 milvus 容器运行"
elif sudo docker ps &>/dev/null; then
    echo "⚠️  需要使用 sudo"
    echo "建议: 退出并重新登录 SSH 使权限生效"
    sudo docker ps --filter "name=milvus" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  无 milvus 容器运行"
else
    echo "❌ Docker 无法访问"
fi
echo ""

