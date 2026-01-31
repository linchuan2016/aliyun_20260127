#!/bin/bash
# 检查 Python 源码下载状态
# 使用方法: bash deploy/check-python-download.sh

echo "=========================================="
echo "检查 Python 源码下载状态"
echo "=========================================="
echo ""

cd /tmp

# 检查所有可能的文件名（wget 可能会自动重命名）
echo ">>> 查找下载的文件..."
FILES=$(ls -lh Python-3.10.13.tgz* 2>/dev/null || echo "")

if [ -z "$FILES" ]; then
    echo "✗ 未找到任何 Python-3.10.13.tgz 文件"
    echo ""
    echo "可能的情况："
    echo "  1. 下载尚未开始"
    echo "  2. 文件下载到了其他位置"
    echo ""
    echo "建议："
    echo "  1. 检查是否有 wget 进程在运行: ps aux | grep wget"
    echo "  2. 检查 /tmp 目录: ls -lh /tmp/Python*"
    echo "  3. 使用国内镜像重新下载（更快）"
    exit 1
fi

echo "找到以下文件："
echo "$FILES"
echo ""

# 检查每个文件
for file in Python-3.10.13.tgz*; do
    if [ -f "$file" ]; then
        echo ">>> 检查文件: $file"
        SIZE=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
        EXPECTED_SIZE=26111363  # Python 3.10.13 的预期大小（字节）
        SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc 2>/dev/null || echo "0")
        EXPECTED_MB=$(echo "scale=2; $EXPECTED_SIZE / 1024 / 1024" | bc 2>/dev/null || echo "25")
        
        echo "  文件大小: ${SIZE_MB} MB (预期: ${EXPECTED_MB} MB)"
        echo "  文件大小: $SIZE 字节 (预期: $EXPECTED_SIZE 字节)"
        
        # 检查是否有进程正在写入
        LSOF=$(lsof "$file" 2>/dev/null | grep -v COMMAND || echo "")
        if [ -n "$LSOF" ]; then
            echo "  ⚠ 文件正在被写入（下载中）:"
            echo "$LSOF" | head -3
        fi
        
        # 检查文件完整性
        if [ "$SIZE" -eq "$EXPECTED_SIZE" ]; then
            echo "  ✓ 文件大小正确，下载可能已完成"
            
            # 尝试验证 tar 文件
            echo "  >>> 验证 tar 文件完整性..."
            if tar -tzf "$file" > /dev/null 2>&1; then
                echo "  ✓ tar 文件完整，可以解压"
                echo ""
                echo "可以执行以下命令解压："
                echo "  tar -xzf $file"
            else
                echo "  ✗ tar 文件可能损坏，建议重新下载"
            fi
        elif [ "$SIZE" -lt "$EXPECTED_SIZE" ]; then
            PERCENT=$(echo "scale=1; $SIZE * 100 / $EXPECTED_SIZE" | bc 2>/dev/null || echo "0")
            echo "  ⚠ 文件未下载完成 (${PERCENT}%)"
            if [ -z "$LSOF" ]; then
                echo "  ⚠ 没有进程在写入，下载可能已中断"
                echo "  建议：删除不完整的文件并重新下载"
            fi
        else
            echo "  ⚠ 文件大小异常，可能下载错误"
        fi
        echo ""
    fi
done

# 检查是否有 wget 进程
echo ">>> 检查下载进程..."
WGET_PROCESS=$(ps aux | grep -E "wget.*Python-3.10.13" | grep -v grep || echo "")
if [ -n "$WGET_PROCESS" ]; then
    echo "发现正在运行的 wget 进程："
    echo "$WGET_PROCESS"
    echo ""
    echo "下载仍在进行中，请等待..."
else
    echo "没有发现 wget 下载进程"
fi

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="

