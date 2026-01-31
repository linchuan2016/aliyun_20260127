#!/bin/bash
# 修复 Docker 配置文件并恢复服务

set -e

echo "=========================================="
echo "修复 Docker 配置文件"
echo "=========================================="
echo ""

# 步骤 1: 备份当前配置（如果存在）
echo "步骤 1: 备份当前配置..."
if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
    echo "✓ 已备份到: /etc/docker/daemon.json.backup.*"
else
    echo "⚠️  配置文件不存在，将创建新配置"
fi
echo ""

# 步骤 2: 删除或修复损坏的配置
echo "步骤 2: 删除损坏的配置..."
if [ -f /etc/docker/daemon.json ]; then
    sudo rm -f /etc/docker/daemon.json
    echo "✓ 已删除损坏的配置文件"
fi
echo ""

# 步骤 3: 创建正确的配置文件
echo "步骤 3: 创建正确的配置文件..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://huecker.io",
    "https://noohub.net"
  ]
}
EOF

# 验证 JSON 格式
echo "验证 JSON 格式..."
if python3 -m json.tool /etc/docker/daemon.json > /dev/null 2>&1 || python -m json.tool /etc/docker/daemon.json > /dev/null 2>&1; then
    echo "✓ JSON 格式正确"
else
    echo "⚠️  无法验证 JSON 格式（可能没有 Python），但配置已写入"
fi
echo ""

# 显示配置内容
echo "配置文件内容:"
cat /etc/docker/daemon.json
echo ""

# 步骤 4: 重新加载 systemd 并启动 Docker
echo "步骤 4: 重新加载配置并启动 Docker..."
sudo systemctl daemon-reload
echo "✓ systemd 配置已重新加载"
echo ""

# 尝试启动 Docker
echo "启动 Docker 服务..."
if sudo systemctl start docker; then
    echo "✓ Docker 服务启动成功"
else
    echo "❌ Docker 服务启动失败"
    echo ""
    echo "查看错误信息:"
    sudo systemctl status docker -l --no-pager
    echo ""
    echo "查看详细日志:"
    sudo journalctl -u docker -n 30 --no-pager
    echo ""
    echo "尝试修复..."
    
    # 如果启动失败，尝试重置配置
    echo "尝试使用最小配置..."
    sudo tee /etc/docker/daemon.json <<-'MINIMAL_EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io"
  ]
}
MINIMAL_EOF
    
    sudo systemctl daemon-reload
    sudo systemctl start docker
    
    if sudo systemctl is-active --quiet docker; then
        echo "✓ Docker 服务已使用最小配置启动"
    else
        echo "❌ Docker 仍然无法启动"
        echo ""
        echo "请手动检查:"
        echo "  1. sudo systemctl status docker"
        echo "  2. sudo journalctl -u docker -n 50"
        exit 1
    fi
fi
echo ""

# 步骤 5: 等待 Docker 完全启动
echo "等待 Docker 完全启动..."
sleep 5

# 步骤 6: 验证 Docker 运行状态
echo "步骤 5: 验证 Docker 运行状态..."
if sudo systemctl is-active --quiet docker; then
    echo "✓ Docker 服务正在运行"
else
    echo "❌ Docker 服务未运行"
    exit 1
fi

# 测试 Docker 连接
if sudo docker ps &>/dev/null; then
    echo "✓ Docker 连接正常"
    echo ""
    echo "Docker 版本信息:"
    sudo docker --version
else
    echo "❌ Docker 连接失败"
    echo "查看 Docker socket:"
    ls -l /var/run/docker.sock 2>/dev/null || echo "Docker socket 不存在"
    exit 1
fi
echo ""

# 步骤 7: 验证镜像加速配置
echo "步骤 6: 验证镜像加速配置..."
echo "Docker 信息中的镜像源:"
sudo docker info 2>/dev/null | grep -A 5 "Registry Mirrors" || echo "无法获取镜像源信息（可能需要等待）"
echo ""

echo "=========================================="
echo "✅ Docker 配置修复完成！"
echo "=========================================="
echo ""
echo "当前配置:"
cat /etc/docker/daemon.json
echo ""
echo "Docker 服务状态:"
sudo systemctl status docker --no-pager -l | head -10
echo ""

