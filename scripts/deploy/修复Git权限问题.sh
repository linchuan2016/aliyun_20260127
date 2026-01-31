#!/bin/bash
# 修复 Git 权限问题
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/修复Git权限问题.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "修复 Git 权限问题"
echo "=========================================="
echo ""

cd "$DEPLOY_PATH"

# 1. 检查当前用户
CURRENT_USER=$(whoami)
echo "当前用户: $CURRENT_USER"
echo ""

# 2. 修复 .git 目录权限
echo ">>> 1. 修复 .git 目录权限..."
if [ -d ".git" ]; then
    # 确保当前用户拥有 .git 目录
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" .git
    sudo chmod -R 755 .git
    echo "✓ .git 目录权限已修复"
else
    echo "✗ .git 目录不存在"
    exit 1
fi
echo ""

# 3. 修复整个项目目录权限（可选，但推荐）
echo ">>> 2. 修复项目目录权限..."
sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$DEPLOY_PATH"
sudo chmod -R 755 "$DEPLOY_PATH"
# 但 data 目录需要特殊处理（服务用户需要访问）
echo "✓ 项目目录权限已修复"
echo ""

# 4. 配置 Git 安全目录
echo ">>> 3. 配置 Git 安全目录..."
git config --global --add safe.directory "$DEPLOY_PATH" 2>/dev/null || true
echo "✓ Git 安全配置已添加"
echo ""

# 5. 测试 Git 命令
echo ">>> 4. 测试 Git 命令..."
if git status > /dev/null 2>&1; then
    echo "✓ Git 命令正常"
    git status --short | head -5
else
    echo "✗ Git 命令仍然失败"
    echo "尝试使用 sudo 修复..."
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" .git
    sudo chmod -R 755 .git
    git status > /dev/null 2>&1 && echo "✓ 修复成功" || echo "✗ 仍然失败，请检查错误信息"
fi
echo ""

# 6. 清理可能的锁定文件
echo ">>> 5. 清理 Git 锁定文件..."
if [ -f ".git/index.lock" ]; then
    rm -f .git/index.lock
    echo "✓ 已删除 index.lock"
fi
if [ -f ".git/FETCH_HEAD.lock" ]; then
    rm -f .git/FETCH_HEAD.lock
    echo "✓ 已删除 FETCH_HEAD.lock"
fi
echo ""

echo "=========================================="
echo "权限修复完成！"
echo "=========================================="
echo ""
echo "现在可以执行同步脚本："
echo "  bash scripts/deploy/sync-on-server-complete.sh"
echo ""

