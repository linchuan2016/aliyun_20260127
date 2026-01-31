#!/bin/bash
# 修复 Git 权限问题并同步代码
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/修复Git权限并同步.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "修复 Git 权限并同步代码"
echo "=========================================="
echo ""

cd "$DEPLOY_PATH"

# 1. 修复 Git 安全配置
echo ">>> 1. 修复 Git 安全配置..."
git config --global --add safe.directory "$DEPLOY_PATH" 2>/dev/null || true
echo "✓ Git 安全配置已添加"
echo ""

# 2. 验证 Git 配置
echo ">>> 2. 验证 Git 配置..."
git config --global --get-all safe.directory | grep "$DEPLOY_PATH" && echo "✓ 配置验证成功" || echo "⚠ 配置可能未生效"
echo ""

# 3. 测试 Git 命令
echo ">>> 3. 测试 Git 命令..."
if git status > /dev/null 2>&1; then
    echo "✓ Git 命令正常"
else
    echo "✗ Git 命令仍然失败，尝试其他方法..."
    # 尝试使用 sudo 运行
    sudo git config --global --add safe.directory "$DEPLOY_PATH" 2>/dev/null || true
fi
echo ""

# 4. 执行完整同步
echo ">>> 4. 执行完整同步..."
bash scripts/deploy/sync-on-server-complete.sh

echo ""
echo "=========================================="
echo "完成！"
echo "=========================================="

