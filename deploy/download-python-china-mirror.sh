#!/bin/bash
# 使用国内镜像下载 Python 源码（加速下载）
# 使用方法: bash deploy/download-python-china-mirror.sh

set -e

PYTHON_VERSION="3.10.13"
PYTHON_FILE="Python-${PYTHON_VERSION}.tgz"
EXPECTED_SIZE=26111363  # 25MB

echo "=========================================="
echo "使用国内镜像下载 Python ${PYTHON_VERSION}"
echo "=========================================="
echo ""

cd /tmp

# 清理旧文件
if [ -f "$PYTHON_FILE" ]; then
    echo ">>> 发现已存在的文件，检查完整性..."
    CURRENT_SIZE=$(stat -c%s "$PYTHON_FILE" 2>/dev/null || stat -f%z "$PYTHON_FILE" 2>/dev/null || echo "0")
    if [ "$CURRENT_SIZE" -eq "$EXPECTED_SIZE" ]; then
        if tar -tzf "$PYTHON_FILE" > /dev/null 2>&1; then
            echo "✓ 文件已存在且完整，跳过下载"
            exit 0
        else
            echo "⚠ 文件存在但可能损坏，将重新下载"
            rm -f "$PYTHON_FILE"
        fi
    else
        echo "⚠ 文件不完整，将重新下载"
        rm -f "$PYTHON_FILE"
    fi
fi

# 清理可能的临时文件
rm -f "${PYTHON_FILE}".* 2>/dev/null || true

echo ">>> 尝试使用国内镜像下载..."
echo ""

# 镜像列表（按优先级排序）
MIRRORS=(
    "https://mirrors.huaweicloud.com/python/${PYTHON_VERSION}/${PYTHON_FILE}"
    "https://mirrors.aliyun.com/python-release/${PYTHON_VERSION}/${PYTHON_FILE}"
    "https://mirror.baidu.com/python/${PYTHON_VERSION}/${PYTHON_FILE}"
    "https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_FILE}"
)

SUCCESS=false
for MIRROR_URL in "${MIRRORS[@]}"; do
    echo "尝试镜像: $MIRROR_URL"
    
    if wget --timeout=10 --tries=3 -O "$PYTHON_FILE" "$MIRROR_URL" 2>&1 | tee /tmp/wget.log; then
        # 检查文件大小
        DOWNLOADED_SIZE=$(stat -c%s "$PYTHON_FILE" 2>/dev/null || stat -f%z "$PYTHON_FILE" 2>/dev/null || echo "0")
        
        if [ "$DOWNLOADED_SIZE" -eq "$EXPECTED_SIZE" ]; then
            # 验证 tar 文件
            if tar -tzf "$PYTHON_FILE" > /dev/null 2>&1; then
                echo ""
                echo "✓ 下载成功！"
                echo "  文件: $PYTHON_FILE"
                echo "  大小: $(echo "scale=2; $DOWNLOADED_SIZE / 1024 / 1024" | bc) MB"
                echo "  来源: $MIRROR_URL"
                SUCCESS=true
                break
            else
                echo "✗ 文件损坏，尝试下一个镜像..."
                rm -f "$PYTHON_FILE"
            fi
        else
            echo "✗ 文件大小不正确 (${DOWNLOADED_SIZE} vs ${EXPECTED_SIZE})，尝试下一个镜像..."
            rm -f "$PYTHON_FILE"
        fi
    else
        echo "✗ 下载失败，尝试下一个镜像..."
        rm -f "$PYTHON_FILE"
    fi
    echo ""
done

if [ "$SUCCESS" = false ]; then
    echo "=========================================="
    echo "✗ 所有镜像下载失败"
    echo "=========================================="
    echo ""
    echo "建议："
    echo "  1. 检查网络连接"
    echo "  2. 手动下载: wget https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_FILE}"
    echo "  3. 或使用代理下载"
    exit 1
fi

echo ""
echo "=========================================="
echo "下载完成！可以继续执行编译步骤"
echo "=========================================="
echo ""
echo "下一步："
echo "  tar -xzf $PYTHON_FILE"
echo "  cd Python-${PYTHON_VERSION}"
echo "  ./configure --enable-optimizations --with-ensurepip=install --prefix=/usr/local"

