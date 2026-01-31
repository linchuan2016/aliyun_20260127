#!/bin/bash
# 使用国内镜像下载 Python 源码（推荐用于阿里云服务器）
# 使用方法: bash deploy/download-python-mirror.sh

set -e

PYTHON_VERSION="3.10.13"
PYTHON_FILE="Python-${PYTHON_VERSION}.tgz"
EXPECTED_SIZE=26111363  # 25MB (26,111,363 字节)

echo "=========================================="
echo "使用国内镜像下载 Python ${PYTHON_VERSION}"
echo "=========================================="
echo ""

cd /tmp

# 清理旧文件
echo ">>> 清理旧文件..."
rm -f Python-3.10.13.tgz* 2>/dev/null || true
pkill wget 2>/dev/null || true
sleep 1
echo "✓ 清理完成"
echo ""

# 国内镜像列表（按速度排序）
echo ">>> 尝试使用国内镜像下载..."
echo ""

MIRRORS=(
    "https://mirrors.huaweicloud.com/python/${PYTHON_VERSION}/${PYTHON_FILE}"
    "https://mirrors.aliyun.com/python-release/${PYTHON_VERSION}/${PYTHON_FILE}"
    "https://mirror.baidu.com/python/${PYTHON_VERSION}/${PYTHON_FILE}"
    "https://mirrors.tuna.tsinghua.edu.cn/python-release/${PYTHON_VERSION}/${PYTHON_FILE}"
    "https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_FILE}"
)

MIRROR_NAMES=(
    "华为云镜像"
    "阿里云镜像"
    "百度云镜像"
    "清华大学镜像"
    "Python 官方源"
)

SUCCESS=false
for i in "${!MIRRORS[@]}"; do
    MIRROR_URL="${MIRRORS[$i]}"
    MIRROR_NAME="${MIRROR_NAMES[$i]}"
    
    echo "尝试 [$MIRROR_NAME]:"
    echo "  $MIRROR_URL"
    
    # 下载文件，显示进度
    if wget --timeout=30 --tries=2 --progress=bar:force -O "$PYTHON_FILE" "$MIRROR_URL" 2>&1; then
        # 检查文件大小
        DOWNLOADED_SIZE=$(stat -c%s "$PYTHON_FILE" 2>/dev/null || stat -f%z "$PYTHON_FILE" 2>/dev/null || echo "0")
        DOWNLOADED_MB=$(echo "scale=2; $DOWNLOADED_SIZE / 1024 / 1024" | bc 2>/dev/null || echo "0")
        
        echo ""
        echo "下载大小: ${DOWNLOADED_MB} MB ($DOWNLOADED_SIZE 字节)"
        
        if [ "$DOWNLOADED_SIZE" -eq "$EXPECTED_SIZE" ]; then
            # 验证 tar 文件完整性
            echo "验证文件完整性..."
            if tar -tzf "$PYTHON_FILE" > /dev/null 2>&1; then
                echo ""
                echo "✓ 下载成功！"
                echo "  文件: $PYTHON_FILE"
                echo "  大小: ${DOWNLOADED_MB} MB"
                echo "  来源: $MIRROR_NAME"
                SUCCESS=true
                break
            else
                echo "✗ 文件损坏，尝试下一个镜像..."
                rm -f "$PYTHON_FILE"
            fi
        else
            echo "✗ 文件大小不正确 (预期: 25MB)，尝试下一个镜像..."
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
    echo "可能的原因："
    echo "  1. 网络连接问题"
    echo "  2. 镜像服务器暂时不可用"
    echo ""
    echo "建议："
    echo "  1. 检查网络连接: ping mirrors.huaweicloud.com"
    echo "  2. 稍后重试"
    echo "  3. 手动下载: wget https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_FILE}"
    exit 1
fi

echo ""
echo "=========================================="
echo "下载完成！"
echo "=========================================="
echo ""
echo "下一步操作："
echo "  cd /tmp"
echo "  tar -xzf $PYTHON_FILE"
echo "  cd Python-${PYTHON_VERSION}"
echo "  ./configure --enable-optimizations --with-ensurepip=install --prefix=/usr/local"
echo "  make -j\$(nproc)"
echo "  sudo make altinstall"

