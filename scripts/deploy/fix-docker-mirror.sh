#!/bin/bash
# 修复 Docker 镜像加速配置

echo "=========================================="
echo "配置 Docker 镜像加速（阿里云）"
echo "=========================================="
echo ""

# 配置镜像加速
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://dockerhub.azk8s.cn",
    "https://reg-mirror.qiniu.com"
  ]
}
EOF

echo "✓ 镜像加速配置完成"
echo ""

# 重启 Docker 服务使配置生效
echo "重启 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl restart docker

echo "✓ Docker 服务已重启"
echo ""

# 验证配置
echo "当前 Docker 镜像加速配置:"
cat /etc/docker/daemon.json
echo ""

echo "测试镜像拉取（拉取一个小镜像测试）..."
docker pull hello-world || echo "⚠️  测试拉取失败，但配置已更新"
echo ""

echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "现在可以重新运行启动脚本:"
echo "  sudo ./scripts/deploy/start-milvus.sh"
echo ""

