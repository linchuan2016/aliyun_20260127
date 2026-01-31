#!/bin/bash
# 为项目虚拟环境配置 pip 国内镜像源
# 在服务器上执行: bash deploy/configure-pip-mirror-for-venv.sh

set -e

echo "=========================================="
echo "为项目虚拟环境配置 pip 国内镜像源"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"
VENV_PATH="$DEPLOY_PATH/venv"

# 检查虚拟环境是否存在
if [ ! -d "$VENV_PATH" ]; then
    echo "✗ 虚拟环境不存在: $VENV_PATH"
    exit 1
fi

echo "虚拟环境路径: $VENV_PATH"
echo ""

# 创建 pip 配置目录
PIP_CONF_DIR="$VENV_PATH/pip"
PIP_CONF_FILE="$PIP_CONF_DIR/pip.conf"

mkdir -p "$PIP_CONF_DIR"

# 使用阿里云镜像（最快）
MIRROR_URL="https://mirrors.aliyun.com/pypi/simple/"
MIRROR_HOST="mirrors.aliyun.com"

echo "配置镜像源: 阿里云"
echo "镜像地址: $MIRROR_URL"
echo ""

# 创建配置文件
tee "$PIP_CONF_FILE" > /dev/null << EOF
[global]
index-url = $MIRROR_URL
trusted-host = $MIRROR_HOST
timeout = 120

[install]
trusted-host = $MIRROR_HOST
EOF

echo "✓ 配置文件已创建: $PIP_CONF_FILE"
echo ""

# 显示配置内容
echo "配置内容："
cat "$PIP_CONF_FILE"
echo ""

# 测试配置（激活虚拟环境测试）
echo ">>> 测试配置..."
source "$VENV_PATH/bin/activate"

# 测试 pip 配置
if pip config list 2>/dev/null | grep -q "index-url"; then
    echo "✓ 配置生效"
    echo ""
    echo "当前配置："
    pip config list | grep -E "index-url|trusted-host" || echo "使用默认配置"
else
    # 如果 pip config 不可用，直接测试安装速度
    echo "测试镜像源速度..."
    time pip install --dry-run requests > /dev/null 2>&1 && echo "✓ 镜像源可用"
fi

deactivate

echo ""
echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "现在在虚拟环境中使用 pip 安装包会更快："
echo "  source $VENV_PATH/bin/activate"
echo "  pip install package_name"
echo ""

