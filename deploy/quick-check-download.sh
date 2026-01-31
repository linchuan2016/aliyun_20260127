#!/bin/bash
# 快速检查下载状态（可在服务器上直接创建）
# 使用方法: bash quick-check-download.sh

cd /tmp

echo "=========================================="
echo "检查 Python 源码下载状态"
echo "=========================================="
echo ""

# 检查文件
echo ">>> 查找 Python-3.10.13.tgz 文件..."
ls -lh Python-3.10.13.tgz* 2>/dev/null || echo "未找到文件"

echo ""
echo ">>> 检查下载进程..."
ps aux | grep -E "wget.*Python-3.10.13" | grep -v grep || echo "没有下载进程"

echo ""
echo ">>> 文件分析："
EXPECTED_SIZE=26111363  # 25MB

for file in Python-3.10.13.tgz*; do
    if [ -f "$file" ]; then
        SIZE=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")
        SIZE_MB=$(echo "scale=2; $SIZE / 1024 / 1024" | bc 2>/dev/null || echo "0")
        
        echo ""
        echo "文件: $file"
        echo "  大小: ${SIZE_MB} MB ($SIZE 字节)"
        
        if [ "$SIZE" -eq "$EXPECTED_SIZE" ]; then
            echo "  ✓ 大小正确 (25MB)"
            if tar -tzf "$file" > /dev/null 2>&1; then
                echo "  ✓ 文件完整，可以使用！"
                echo "  建议: 使用此文件解压: tar -xzf $file"
            else
                echo "  ✗ 文件可能损坏"
            fi
        elif [ "$SIZE" -lt "$EXPECTED_SIZE" ]; then
            PERCENT=$(echo "scale=1; $SIZE * 100 / $EXPECTED_SIZE" | bc 2>/dev/null || echo "0")
            echo "  ⚠ 未完成 (${PERCENT}%)"
        else
            echo "  ⚠ 大小异常"
        fi
    fi
done

echo ""
echo "=========================================="

