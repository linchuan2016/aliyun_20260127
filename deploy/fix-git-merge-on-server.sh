#!/bin/bash
# 在服务器上解决 Git 合并冲突并拉取最新代码
# 在服务器上执行: bash deploy/fix-git-merge-on-server.sh

set -e

echo "=========================================="
echo "解决 Git 合并冲突并拉取最新代码"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"
cd "$DEPLOY_PATH"

# 1. 检查 Git 状态
echo ">>> 1. 检查 Git 状态..."
git status --short
echo ""

# 2. 备份本地修改的文件
echo ">>> 2. 备份本地修改的文件..."
CONFLICT_FILE="deploy/检查Python兼容性.py"
if [ -f "$CONFLICT_FILE" ]; then
    BACKUP_FILE="${CONFLICT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$CONFLICT_FILE" "$BACKUP_FILE"
    echo "✓ 已备份到: $BACKUP_FILE"
fi
echo ""

# 3. 暂存本地修改
echo ">>> 3. 暂存本地修改..."
git stash push -m "backup-local-changes-$(date +%Y%m%d_%H%M%S)" 2>/dev/null || echo "没有需要暂存的修改"
echo "✓ 已暂存"
echo ""

# 4. 拉取最新代码
echo ">>> 4. 拉取最新代码..."
git pull gitee main
echo "✓ 拉取成功"
echo ""

# 5. 恢复暂存的修改（如果需要）
echo ">>> 5. 检查是否有暂存的修改..."
if git stash list | grep -q "backup"; then
    echo "发现暂存的修改，可以选择恢复："
    echo "  git stash pop  # 恢复并应用修改"
    echo "  git stash drop  # 丢弃暂存的修改"
else
    echo "没有暂存的修改"
fi
echo ""

# 6. 验证文件是否存在
echo ">>> 6. 验证脚本文件..."
if [ -f "deploy/force-install-correct-versions.sh" ]; then
    echo "✓ force-install-correct-versions.sh 存在"
    ls -lh deploy/force-install-correct-versions.sh
else
    echo "✗ force-install-correct-versions.sh 不存在"
fi

if [ -f "deploy/fix-version-downgrade.sh" ]; then
    echo "✓ fix-version-downgrade.sh 存在"
else
    echo "✗ fix-version-downgrade.sh 不存在"
fi

if [ -f "deploy/install-dependencies-with-mirror.sh" ]; then
    echo "✓ install-dependencies-with-mirror.sh 存在"
else
    echo "✗ install-dependencies-with-mirror.sh 不存在"
fi
echo ""

echo "=========================================="
echo "✓ 完成！现在可以执行脚本了"
echo "=========================================="
echo ""
echo "执行安装脚本："
echo "  bash deploy/force-install-correct-versions.sh"
echo ""

