#!/bin/bash
# 修复 Docker 权限问题

echo "=========================================="
echo "修复 Docker 权限问题"
echo "=========================================="
echo ""

# 检查当前用户
CURRENT_USER=$(whoami)
echo "当前用户: $CURRENT_USER"
echo ""

# 检查用户是否在 docker 组中
if groups | grep -q docker; then
    echo "✓ 用户已在 docker 组中"
else
    echo "步骤 1: 将用户添加到 docker 组..."
    sudo usermod -aG docker $CURRENT_USER
    echo "✓ 用户已添加到 docker 组"
    echo ""
    echo "⚠️  重要: 需要重新登录或执行以下命令使组权限生效:"
    echo "  newgrp docker"
    echo "  或"
    echo "  退出并重新登录 SSH"
    echo ""
fi

# 检查 docker.sock 权限
echo "步骤 2: 检查 Docker socket 权限..."
DOCKER_SOCK="/var/run/docker.sock"
if [ -e "$DOCKER_SOCK" ]; then
    SOCK_PERM=$(stat -c "%a" "$DOCKER_SOCK" 2>/dev/null || echo "unknown")
    echo "Docker socket 权限: $SOCK_PERM"
    
    if [ "$SOCK_PERM" != "666" ] && [ "$SOCK_PERM" != "660" ]; then
        echo "调整 Docker socket 权限..."
        sudo chmod 666 /var/run/docker.sock 2>/dev/null || {
            echo "无法直接修改权限，使用组方式..."
            sudo chgrp docker /var/run/docker.sock
            sudo chmod 660 /var/run/docker.sock
        }
        echo "✓ 权限已调整"
    else
        echo "✓ 权限正常"
    fi
else
    echo "⚠️  Docker socket 不存在，Docker 可能未运行"
fi
echo ""

echo "步骤 3: 测试 Docker 权限..."
if docker ps &>/dev/null; then
    echo "✓ Docker 权限正常，可以执行 docker 命令"
elif sudo docker ps &>/dev/null; then
    echo "⚠️  需要使用 sudo 执行 docker 命令"
    echo "建议: 执行 'newgrp docker' 或重新登录"
else
    echo "❌ Docker 无法访问，请检查 Docker 服务状态"
    sudo systemctl status docker
fi
echo ""

echo "=========================================="
echo "修复完成"
echo "=========================================="
echo ""
echo "如果仍然有权限问题，请执行以下之一:"
echo ""
echo "方法 1: 使用 newgrp（临时生效）"
echo "  newgrp docker"
echo "  docker ps"
echo ""
echo "方法 2: 重新登录 SSH（永久生效）"
echo "  退出当前 SSH 会话，重新登录"
echo ""
echo "方法 3: 使用 sudo（临时方案）"
echo "  sudo docker ps"
echo ""

