#!/bin/bash
# 在阿里云服务器上升级 Python 版本
# 建议使用 Python 3.10 或 3.11（稳定版本）
# 使用方法: bash deploy/升级Python版本.sh

set -e

echo "=========================================="
echo "升级 Python 版本"
echo "=========================================="
echo ""

# 检查当前 Python 版本
echo ">>> 检查当前 Python 版本..."
CURRENT_PYTHON=$(python3 --version 2>&1 || echo "未安装")
echo "当前 Python: $CURRENT_PYTHON"

PYTHON_VERSION="3.10.13"  # 建议使用 3.10 或 3.11
echo "目标 Python 版本: $PYTHON_VERSION"
echo ""

# 确认
read -p "是否继续升级到 Python $PYTHON_VERSION? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 1
fi

# 安装编译依赖
echo ">>> 安装编译依赖..."
if command -v yum > /dev/null; then
    # CentOS/RHEL
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y openssl-devel bzip2-devel libffi-devel zlib-devel readline-devel sqlite-devel
elif command -v apt-get > /dev/null; then
    # Ubuntu/Debian
    sudo apt-get update
    sudo apt-get install -y build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev wget libbz2-dev
else
    echo "✗ 无法识别系统包管理器"
    exit 1
fi
echo "✓ 编译依赖安装完成"
echo ""

# 下载 Python 源码
echo ">>> 下载 Python $PYTHON_VERSION 源码..."
cd /tmp
if [ -d "Python-$PYTHON_VERSION" ]; then
    rm -rf "Python-$PYTHON_VERSION"
fi

wget "https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz"
tar -xzf "Python-$PYTHON_VERSION.tgz"
cd "Python-$PYTHON_VERSION"
echo "✓ 源码下载完成"
echo ""

# 编译安装
echo ">>> 编译安装 Python $PYTHON_VERSION..."
./configure --enable-optimizations --with-ensurepip=install --prefix=/usr/local
make -j$(nproc)
sudo make altinstall
echo "✓ Python $PYTHON_VERSION 安装完成"
echo ""

# 验证安装
echo ">>> 验证安装..."
/usr/local/bin/python3.10 --version
/usr/local/bin/pip3.10 --version
echo ""

# 更新虚拟环境
echo ">>> 更新项目虚拟环境..."
DEPLOY_PATH="/var/www/my-fullstack-app"
cd "$DEPLOY_PATH"

# 备份旧虚拟环境
if [ -d "venv" ]; then
    echo "备份旧虚拟环境..."
    mv venv venv.backup.$(date +%Y%m%d_%H%M%S)
fi

# 创建新虚拟环境
echo "创建新虚拟环境..."
/usr/local/bin/python3.10 -m venv venv
source venv/bin/activate

# 升级 pip
pip install --upgrade pip

# 安装依赖
echo "安装项目依赖..."
cd backend
pip install -r requirements.txt
cd ..
echo "✓ 虚拟环境更新完成"
echo ""

# 测试导入
echo ">>> 测试代码兼容性..."
cd backend
python3 -c "
import sys
print(f'Python 版本: {sys.version}')
print('测试导入模块...')
try:
    from database import SessionLocal
    from models import Article, User, Product, Memo
    from auth import get_password_hash, verify_password
    from main import app
    print('✓ 所有模块导入成功')
    print('✓ 代码兼容性检查通过')
except Exception as e:
    print(f'✗ 导入失败: {e}')
    import traceback
    traceback.print_exc()
    sys.exit(1)
"
echo ""

# 重启服务
echo ">>> 重启服务..."
sudo systemctl restart my-fullstack-app
sleep 3
echo "✓ 服务已重启"
echo ""

# 验证服务
echo ">>> 验证服务..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ 服务运行正常 (HTTP $HTTP_CODE)"
else
    echo "⚠ 服务可能有问题 (HTTP $HTTP_CODE)"
    echo "查看日志: journalctl -u my-fullstack-app -n 50 --no-pager"
fi
echo ""

echo "=========================================="
echo "升级完成！"
echo "=========================================="
echo ""
echo "新 Python 版本: $(/usr/local/bin/python3.10 --version)"
echo "虚拟环境 Python: $(venv/bin/python --version)"
echo ""
echo "如果遇到问题，可以恢复旧虚拟环境："
echo "  mv venv venv.backup.* venv"

