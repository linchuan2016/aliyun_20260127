#!/bin/bash
# 从 GitHub 克隆代码到阿里云服务器
# 在服务器上执行此脚本

GITHUB_REPO="https://github.com/linchuan2016/aliyun_20260127.git"
TARGET_DIR="/var/www/my-fullstack-app"

echo "========================================"
echo "  从 GitHub 克隆代码到阿里云服务器"
echo "========================================"
echo ""
echo "GitHub 仓库: $GITHUB_REPO"
echo "目标目录: $TARGET_DIR"
echo ""

# 检查目录是否已存在
if [ -d "$TARGET_DIR" ]; then
    echo "⚠️  目录 $TARGET_DIR 已存在"
    read -p "是否删除并重新克隆? (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "删除旧目录..."
        rm -rf $TARGET_DIR
    else
        echo "已取消"
        exit 0
    fi
fi

# 创建父目录
mkdir -p $(dirname $TARGET_DIR)

# 克隆代码
echo "开始克隆代码..."
git clone $GITHUB_REPO $TARGET_DIR

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 代码克隆成功！"
    echo ""
    echo "下一步操作:"
    echo "1. cd $TARGET_DIR"
    echo "2. 创建虚拟环境: cd backend && python3 -m venv ../venv"
    echo "3. 参考部署文档继续配置"
else
    echo ""
    echo "✗ 克隆失败，请检查："
    echo "  - 服务器是否安装了 git: git --version"
    echo "  - 网络连接是否正常"
    echo "  - GitHub 仓库地址是否正确"
fi

