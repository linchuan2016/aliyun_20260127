#!/bin/bash
# 验证 Python 源码文件并开始编译
# 使用方法: bash deploy/verify-and-compile-python.sh

set -e

PYTHON_VERSION="3.10.13"
PYTHON_FILE="Python-${PYTHON_VERSION}.tgz"
EXPECTED_SIZE=26111363

echo "=========================================="
echo "验证并编译 Python ${PYTHON_VERSION}"
echo "=========================================="
echo ""

cd /tmp

# 验证文件
echo ">>> 验证下载的文件..."
if [ ! -f "$PYTHON_FILE" ]; then
    echo "✗ 文件不存在: $PYTHON_FILE"
    exit 1
fi

FILE_SIZE=$(stat -c%s "$PYTHON_FILE" 2>/dev/null || stat -f%z "$PYTHON_FILE" 2>/dev/null || echo "0")
FILE_SIZE_MB=$(echo "scale=2; $FILE_SIZE / 1024 / 1024" | bc 2>/dev/null || echo "0")

echo "文件: $PYTHON_FILE"
echo "大小: ${FILE_SIZE_MB} MB ($FILE_SIZE 字节)"

if [ "$FILE_SIZE" -ne "$EXPECTED_SIZE" ]; then
    echo "✗ 文件大小不正确 (预期: 25MB)"
    exit 1
fi

echo "✓ 文件大小正确"

# 验证 tar 文件完整性
echo ">>> 验证 tar 文件完整性..."
if tar -tzf "$PYTHON_FILE" > /dev/null 2>&1; then
    echo "✓ 文件完整，可以解压"
else
    echo "✗ 文件损坏，请重新下载"
    exit 1
fi
echo ""

# 解压
echo ">>> 解压文件..."
if [ -d "Python-$PYTHON_VERSION" ]; then
    echo "清理旧目录..."
    rm -rf "Python-$PYTHON_VERSION"
fi

tar -xzf "$PYTHON_FILE"
cd "Python-$PYTHON_VERSION"
echo "✓ 解压完成"
echo ""

# 配置
echo ">>> 配置编译选项..."
./configure --enable-optimizations --with-ensurepip=install --prefix=/usr/local
echo "✓ 配置完成"
echo ""

# 编译
echo ">>> 开始编译（这可能需要 10-30 分钟）..."
echo "使用 $(nproc) 个 CPU 核心并行编译"
echo ""
make -j$(nproc)

echo ""
echo "✓ 编译完成"
echo ""

# 安装
echo ">>> 安装 Python ${PYTHON_VERSION}..."
sudo make altinstall
echo "✓ 安装完成"
echo ""

# 验证安装
echo ">>> 验证安装..."
/usr/local/bin/python3.10 --version
/usr/local/bin/pip3.10 --version
echo ""

echo "=========================================="
echo "Python ${PYTHON_VERSION} 安装成功！"
echo "=========================================="
echo ""
echo "下一步：更新项目虚拟环境"
echo "  cd /var/www/my-fullstack-app"
echo "  mv venv venv.backup.\$(date +%Y%m%d_%H%M%S)"
echo "  /usr/local/bin/python3.10 -m venv venv"
echo "  source venv/bin/activate"
echo "  pip install --upgrade pip"
echo "  cd backend"
echo "  pip install -r requirements.txt"

