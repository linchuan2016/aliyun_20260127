#!/bin/bash
# 清理之前下载的 Python 源码文件
# 使用方法: bash deploy/clean-python-downloads.sh

echo "=========================================="
echo "清理 Python 源码下载文件"
echo "=========================================="
echo ""

cd /tmp

# 停止所有 wget 进程
echo ">>> 停止所有 wget 下载进程..."
pkill wget 2>/dev/null && echo "✓ 已停止 wget 进程" || echo "没有运行中的 wget 进程"
sleep 1

# 列出要删除的文件
echo ""
echo ">>> 查找要删除的文件..."
FILES=$(ls Python-3.10.13.tgz* 2>/dev/null || echo "")

if [ -z "$FILES" ]; then
    echo "✓ 没有找到需要删除的文件"
    exit 0
fi

echo "找到以下文件："
ls -lh Python-3.10.13.tgz*

# 确认删除
echo ""
read -p "是否删除以上所有文件? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

# 删除文件
echo ""
echo ">>> 删除文件..."
rm -f Python-3.10.13.tgz*
echo "✓ 文件已删除"

# 验证
echo ""
echo ">>> 验证删除结果..."
REMAINING=$(ls Python-3.10.13.tgz* 2>/dev/null || echo "")
if [ -z "$REMAINING" ]; then
    echo "✓ 所有文件已成功删除"
else
    echo "⚠ 仍有文件残留: $REMAINING"
fi

echo ""
echo "=========================================="
echo "清理完成"
echo "=========================================="

