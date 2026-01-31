#!/bin/bash
# 确保 Docker 服务正在运行

set -e

echo "=========================================="
echo "检查并启动 Docker 服务"
echo "=========================================="
echo ""

# 检查 Docker 服务状态
echo "步骤 1: 检查 Docker 服务状态..."
if sudo systemctl is-active --quiet docker; then
    echo "✓ Docker 服务正在运行"
else
    echo "⚠️  Docker 服务未运行，正在启动..."
    sudo systemctl start docker
    sleep 5
    
    # 再次检查
    if sudo systemctl is-active --quiet docker; then
        echo "✓ Docker 服务已启动"
    else
        echo "❌ Docker 服务启动失败"
        echo "查看错误日志:"
        sudo journalctl -u docker -n 20
        exit 1
    fi
fi
echo ""

# 检查 Docker socket
echo "步骤 2: 检查 Docker socket..."
if [ -S /var/run/docker.sock ]; then
    echo "✓ Docker socket 存在"
    ls -l /var/run/docker.sock
else
    echo "❌ Docker socket 不存在"
    echo "尝试重启 Docker..."
    sudo systemctl restart docker
    sleep 5
fi
echo ""

# 测试 Docker 连接
echo "步骤 3: 测试 Docker 连接..."
if sudo docker ps &>/dev/null; then
    echo "✓ Docker 连接正常"
    sudo docker version | head -5
else
    echo "❌ Docker 连接失败"
    echo "尝试重启 Docker..."
    sudo systemctl restart docker
    sleep 10
    
    if sudo docker ps &>/dev/null; then
        echo "✓ Docker 连接已恢复"
    else
        echo "❌ Docker 仍然无法连接"
        echo "查看 Docker 状态:"
        sudo systemctl status docker
        exit 1
    fi
fi
echo ""

echo "=========================================="
echo "Docker 服务已就绪"
echo "=========================================="
echo ""

