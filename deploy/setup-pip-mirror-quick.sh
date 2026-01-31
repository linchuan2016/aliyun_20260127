#!/bin/bash
# 快速配置 pip 使用国内镜像源（一键配置）
# 在服务器上执行: bash deploy/setup-pip-mirror-quick.sh

echo "=========================================="
echo "快速配置 pip 国内镜像源"
echo "=========================================="
echo ""

# 检测是否在项目目录
if [ -d "/var/www/my-fullstack-app" ]; then
    DEPLOY_PATH="/var/www/my-fullstack-app"
elif [ -d "./venv" ] || [ -d "../venv" ]; then
    DEPLOY_PATH="$(pwd)"
    if [ ! -d "$DEPLOY_PATH/venv" ]; then
        DEPLOY_PATH="$(dirname "$DEPLOY_PATH")"
    fi
else
    echo "未找到项目目录，配置全局 pip 源"
    DEPLOY_PATH=""
fi

# 国内镜像源（阿里云，最快）
MIRROR_URL="https://mirrors.aliyun.com/pypi/simple/"
MIRROR_HOST="mirrors.aliyun.com"

echo "使用镜像源: 阿里云"
echo "镜像地址: $MIRROR_URL"
echo ""

# 1. 配置全局 pip 源（root 用户）
if [ "$EUID" -eq 0 ]; then
    GLOBAL_CONF="/etc/pip.conf"
    echo ">>> 配置全局 pip 源..."
    mkdir -p "$(dirname "$GLOBAL_CONF")"
    tee "$GLOBAL_CONF" > /dev/null << EOF
[global]
index-url = $MIRROR_URL
trusted-host = $MIRROR_HOST
timeout = 120

[install]
trusted-host = $MIRROR_HOST
EOF
    echo "✓ 全局配置已创建: $GLOBAL_CONF"
    echo ""
fi

# 2. 配置用户级别 pip 源
USER_CONF="$HOME/.pip/pip.conf"
echo ">>> 配置用户级别 pip 源..."
mkdir -p "$(dirname "$USER_CONF")"
tee "$USER_CONF" > /dev/null << EOF
[global]
index-url = $MIRROR_URL
trusted-host = $MIRROR_HOST
timeout = 120

[install]
trusted-host = $MIRROR_HOST
EOF
echo "✓ 用户配置已创建: $USER_CONF"
echo ""

# 3. 配置项目虚拟环境 pip 源
if [ -n "$DEPLOY_PATH" ] && [ -d "$DEPLOY_PATH/venv" ]; then
    VENV_CONF="$DEPLOY_PATH/venv/pip/pip.conf"
    echo ">>> 配置项目虚拟环境 pip 源..."
    mkdir -p "$(dirname "$VENV_CONF")"
    tee "$VENV_CONF" > /dev/null << EOF
[global]
index-url = $MIRROR_URL
trusted-host = $MIRROR_HOST
timeout = 120

[install]
trusted-host = $MIRROR_HOST
EOF
    echo "✓ 虚拟环境配置已创建: $VENV_CONF"
    echo ""
fi

# 4. 如果当前在虚拟环境中，也配置
if [ -n "$VIRTUAL_ENV" ]; then
    CURRENT_VENV_CONF="$VIRTUAL_ENV/pip/pip.conf"
    echo ">>> 配置当前虚拟环境 pip 源..."
    mkdir -p "$(dirname "$CURRENT_VENV_CONF")"
    tee "$CURRENT_VENV_CONF" > /dev/null << EOF
[global]
index-url = $MIRROR_URL
trusted-host = $MIRROR_HOST
timeout = 120

[install]
trusted-host = $MIRROR_HOST
EOF
    echo "✓ 当前虚拟环境配置已创建: $CURRENT_VENV_CONF"
    echo ""
fi

echo "=========================================="
echo "✓ 配置完成！"
echo "=========================================="
echo ""
echo "已配置的镜像源："
echo "  1. 用户级别: $USER_CONF"
if [ "$EUID" -eq 0 ]; then
    echo "  2. 全局级别: $GLOBAL_CONF"
fi
if [ -n "$DEPLOY_PATH" ] && [ -d "$DEPLOY_PATH/venv" ]; then
    echo "  3. 项目虚拟环境: $DEPLOY_PATH/venv/pip/pip.conf"
fi
echo ""
echo "现在使用 pip 安装包会更快："
echo "  pip install package_name"
echo ""
echo "测试安装速度："
echo "  pip install --upgrade pip"
echo ""

