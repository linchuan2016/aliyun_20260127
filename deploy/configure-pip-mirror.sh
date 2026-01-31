#!/bin/bash
# 配置 pip 使用国内镜像源（加速安装）
# 在服务器上执行: bash deploy/configure-pip-mirror.sh

echo "=========================================="
echo "配置 pip 使用国内镜像源"
echo "=========================================="
echo ""

# 检测用户
if [ "$EUID" -eq 0 ]; then
    PIP_CONFIG_DIR="/etc/pip.conf"
    USER_CONFIG=""
    echo "检测到 root 用户，将配置全局 pip 源"
else
    PIP_CONFIG_DIR="$HOME/.pip/pip.conf"
    USER_CONFIG="（用户级别）"
    echo "检测到普通用户，将配置用户级别 pip 源"
fi

# 创建配置目录
mkdir -p "$(dirname "$PIP_CONFIG_DIR")" 2>/dev/null || sudo mkdir -p "$(dirname "$PIP_CONFIG_DIR")"

# 国内镜像源列表
MIRRORS=(
    "阿里云: https://mirrors.aliyun.com/pypi/simple/"
    "清华大学: https://pypi.tuna.tsinghua.edu.cn/simple/"
    "华为云: https://mirrors.huaweicloud.com/repository/pypi/simple/"
    "中科大: https://pypi.mirrors.ustc.edu.cn/simple/"
    "豆瓣: https://pypi.douban.com/simple/"
    "腾讯云: https://mirrors.cloud.tencent.com/pypi/simple/"
)

echo "可用的国内镜像源："
for i in "${!MIRRORS[@]}"; do
    echo "  $((i+1)). ${MIRRORS[$i]%%:*}"
done
echo ""

# 默认使用阿里云（最快）
SELECTED_MIRROR="https://mirrors.aliyun.com/pypi/simple/"
SELECTED_NAME="阿里云"

echo "默认使用: $SELECTED_NAME"
echo "镜像地址: $SELECTED_MIRROR"
echo ""

# 创建配置文件
if [ "$EUID" -eq 0 ]; then
    sudo tee "$PIP_CONFIG_DIR" > /dev/null << EOF
[global]
index-url = $SELECTED_MIRROR
trusted-host = mirrors.aliyun.com
timeout = 120

[install]
trusted-host = mirrors.aliyun.com
EOF
else
    tee "$PIP_CONFIG_DIR" > /dev/null << EOF
[global]
index-url = $SELECTED_MIRROR
trusted-host = mirrors.aliyun.com
timeout = 120

[install]
trusted-host = mirrors.aliyun.com
EOF
fi

echo "✓ pip 配置已创建: $PIP_CONFIG_DIR"
echo ""

# 显示配置内容
echo "配置内容："
cat "$PIP_CONFIG_DIR"
echo ""

# 测试配置
echo ">>> 测试配置..."
if pip config list 2>/dev/null | grep -q "index-url"; then
    echo "✓ 配置生效"
    pip config list | grep -E "index-url|trusted-host" || echo "使用默认配置"
else
    echo "⚠ 无法验证配置，但文件已创建"
fi
echo ""

# 如果存在虚拟环境，也配置虚拟环境的 pip
if [ -n "$VIRTUAL_ENV" ]; then
    echo "检测到虚拟环境: $VIRTUAL_ENV"
    VENV_PIP_CONF="$VIRTUAL_ENV/pip.conf"
    mkdir -p "$(dirname "$VENV_PIP_CONF")"
    tee "$VENV_PIP_CONF" > /dev/null << EOF
[global]
index-url = $SELECTED_MIRROR
trusted-host = mirrors.aliyun.com
timeout = 120

[install]
trusted-host = mirrors.aliyun.com
EOF
    echo "✓ 虚拟环境 pip 配置已创建: $VENV_PIP_CONF"
    echo ""
fi

echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "现在可以使用 pip 安装包，速度会更快："
echo "  pip install package_name"
echo ""
echo "如果需要临时使用其他源："
echo "  pip install -i https://pypi.tuna.tsinghua.edu.cn/simple/ package_name"
echo ""
echo "如果需要恢复默认源，删除配置文件："
if [ "$EUID" -eq 0 ]; then
    echo "  sudo rm $PIP_CONFIG_DIR"
else
    echo "  rm $PIP_CONFIG_DIR"
fi
echo ""

