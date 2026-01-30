#!/bin/bash
# 在服务器上直接创建低内存安装脚本的命令
# 复制以下内容到服务器终端执行

cat > /var/www/my-fullstack-app/deploy/install-docker-aliyun-low-memory.sh << 'SCRIPT_EOF'
#!/bin/bash
# 阿里云服务器 Docker 安装脚本（低内存优化版）
# 适用于内存较小的服务器

set -e

echo "=========================================="
echo "安装 Docker（低内存优化版）"
echo "=========================================="
echo ""

# 检查是否已安装 Docker
if command -v docker &> /dev/null; then
    echo "✓ Docker 已安装"
    docker --version
    exit 0
fi

# 检查内存
echo "检查系统内存..."
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
AVAIL_MEM=$(free -m | awk '/^Mem:/{print $7}')
echo "总内存: ${TOTAL_MEM}MB"
echo "可用内存: ${AVAIL_MEM}MB"
echo ""

if [ "$AVAIL_MEM" -lt 500 ]; then
    echo "⚠️  警告: 可用内存不足 500MB，可能影响安装"
    echo "建议:"
    echo "  1. 关闭不必要的服务释放内存"
    echo "  2. 增加服务器内存"
    echo "  3. 或使用 Docker 官方安装脚本（更轻量）"
    echo ""
    read -p "是否继续安装? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "步骤 1: 清理旧版本 Docker（如果存在）..."
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
echo "✓ 清理完成"
echo ""

echo "步骤 2: 分批安装依赖（避免内存不足）..."
# 先安装 yum-utils（最小依赖）
echo "  安装 yum-utils..."
sudo yum install -y yum-utils || {
    echo "⚠️  yum-utils 安装失败，尝试使用官方安装脚本..."
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    sudo systemctl start docker
    sudo systemctl enable docker
    docker --version
    exit 0
}

# 添加 Docker 仓库（不需要 device-mapper-persistent-data 和 lvm2）
echo "步骤 3: 添加 Docker 仓库（使用阿里云镜像）..."
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
echo "✓ 仓库添加完成"
echo ""

# 尝试安装 device-mapper-persistent-data 和 lvm2（可选，某些系统不需要）
echo "步骤 4: 安装可选依赖（如果内存允许）..."
if [ "$AVAIL_MEM" -gt 300 ]; then
    echo "  尝试安装 device-mapper-persistent-data 和 lvm2..."
    sudo yum install -y device-mapper-persistent-data lvm2 2>/dev/null || {
        echo "  ⚠️  可选依赖安装失败，继续安装 Docker（通常不影响使用）..."
    }
else
    echo "  ⚠️  内存不足，跳过可选依赖安装"
fi
echo ""

echo "步骤 5: 安装 Docker CE..."
# 使用 --setopt=install_weak_deps=False 减少依赖
sudo yum install -y --setopt=install_weak_deps=False docker-ce docker-ce-cli containerd.io || {
    echo "⚠️  标准安装失败，尝试最小化安装..."
    # 如果标准安装失败，尝试只安装核心组件
    sudo yum install -y docker-ce docker-ce-cli 2>/dev/null || {
        echo "❌ Docker 安装失败"
        echo ""
        echo "建议使用官方安装脚本:"
        echo "  curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"
        exit 1
    }
}
echo "✓ Docker 安装完成"
echo ""

echo "步骤 6: 配置 Docker 镜像加速（阿里云）..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF
echo "✓ 镜像加速配置完成"
echo ""

echo "步骤 7: 启动 Docker 服务..."
sudo systemctl daemon-reload
sudo systemctl start docker
sudo systemctl enable docker
echo "✓ Docker 服务启动完成"
echo ""

echo "步骤 8: 验证 Docker 安装..."
sudo docker --version
echo "✓ Docker 验证完成"
echo ""

# 跳过 hello-world 测试（节省内存）
echo "=========================================="
echo "Docker 安装成功！"
echo "=========================================="
echo ""
echo "注意: 已跳过 hello-world 测试以节省内存"
echo "如需测试，可运行: sudo docker run hello-world"
echo ""
SCRIPT_EOF

chmod +x /var/www/my-fullstack-app/deploy/install-docker-aliyun-low-memory.sh
echo "脚本创建完成！"

