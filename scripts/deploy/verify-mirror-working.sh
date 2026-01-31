#!/bin/bash
# 验证镜像加速是否真正工作

echo "=========================================="
echo "验证 Docker 镜像加速是否工作"
echo "=========================================="
echo ""

# 检查配置
echo "1. 检查镜像加速配置:"
cat /etc/docker/daemon.json
echo ""

# 检查 Docker 信息
echo "2. 检查 Docker 信息中的镜像源:"
sudo docker info 2>/dev/null | grep -A 10 "Registry Mirrors" || echo "无法获取镜像源信息"
echo ""

# 测试拉取（显示详细输出）
echo "3. 测试拉取镜像（观察是否使用镜像加速）:"
echo "拉取 hello-world..."
sudo docker pull hello-world 2>&1 | head -20
echo ""

# 检查是否访问了 Docker Hub
echo "4. 检查 Docker 日志（最近 20 行）:"
sudo journalctl -u docker -n 20 | grep -i "registry\|mirror\|docker.io" || echo "未找到相关日志"
echo ""

# 检查网络连接
echo "5. 测试镜像源连接:"
echo "测试 hub-mirror.c.163.com..."
ping -c 2 hub-mirror.c.163.com &>/dev/null && echo "✓ 网易镜像源可访问" || echo "✗ 网易镜像源不可访问"

echo "测试 docker.mirrors.ustc.edu.cn..."
ping -c 2 docker.mirrors.ustc.edu.cn &>/dev/null && echo "✓ 中科大镜像源可访问" || echo "✗ 中科大镜像源不可访问"
echo ""

echo "=========================================="
echo "验证完成"
echo "=========================================="
echo ""
echo "如果镜像加速未生效，请："
echo "  1. 确保配置正确: cat /etc/docker/daemon.json"
echo "  2. 重启 Docker: sudo systemctl restart docker"
echo "  3. 验证: sudo docker info | grep Mirrors"
echo ""

