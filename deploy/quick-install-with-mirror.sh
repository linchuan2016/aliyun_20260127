#!/bin/bash
# 使用国内镜像快速安装依赖
# 在服务器上执行: bash deploy/quick-install-with-mirror.sh

set -e

echo "=========================================="
echo "使用国内镜像快速安装依赖"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 国内镜像源（按速度排序）
MIRROR="https://mirrors.aliyun.com/pypi/simple/"
TRUSTED_HOST="mirrors.aliyun.com"

echo "使用镜像源: 阿里云"
echo "镜像地址: $MIRROR"
echo ""

# 激活虚拟环境
cd "$DEPLOY_PATH"
if [ ! -d "venv" ]; then
    echo "✗ 虚拟环境不存在"
    exit 1
fi

source venv/bin/activate

# 升级 pip
echo ">>> 升级 pip..."
pip install --upgrade pip -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --quiet
echo "✓ pip 已升级"
echo ""

# 安装依赖
echo ">>> 安装项目依赖..."
cd backend

# 使用国内镜像安装
pip install -r requirements.txt -i "$MIRROR" --trusted-host "$TRUSTED_HOST"
echo ""

# 显示已安装的包
echo ">>> 已安装的包："
pip list | head -20
echo ""

deactivate

echo "=========================================="
echo "安装完成！"
echo "=========================================="

