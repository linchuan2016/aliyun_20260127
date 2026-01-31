#!/bin/bash
# 同步所有部署脚本到服务器
# 在本地执行: bash deploy/sync-scripts-to-server.sh

echo "=========================================="
echo "同步部署脚本到服务器"
echo "=========================================="
echo ""

# 检查是否在项目根目录
if [ ! -d "deploy" ]; then
    echo "✗ 请在项目根目录执行此脚本"
    exit 1
fi

# 需要同步的脚本列表
SCRIPTS=(
    "deploy/force-install-correct-versions.sh"
    "deploy/fix-version-downgrade.sh"
    "deploy/install-dependencies-with-mirror.sh"
    "deploy/setup-pip-mirror-quick.sh"
    "deploy/configure-pip-mirror-for-venv.sh"
    "deploy/fix-version-conflict.sh"
    "deploy/fix-all-issues.sh"
    "deploy/quick-fix-service.sh"
    "deploy/diagnose-and-fix-service.sh"
    "deploy/检查Python兼容性.py"
)

echo "需要同步的脚本："
for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo "  ✓ $script"
    else
        echo "  ✗ $script (不存在)"
    fi
done
echo ""

# 检查 Git 状态
echo ">>> 检查 Git 状态..."
if ! git status > /dev/null 2>&1; then
    echo "✗ 当前目录不是 Git 仓库"
    exit 1
fi

# 添加所有脚本到 Git
echo ">>> 添加脚本到 Git..."
git add deploy/*.sh deploy/*.py 2>/dev/null || true
git status --short deploy/
echo ""

# 提交
read -p "是否提交这些脚本到 Git? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git commit -m "添加部署脚本：修复 FastAPI 版本兼容性问题" || echo "没有变更需要提交"
    echo "✓ 已提交"
    echo ""
    
    # 推送到 Gitee
    read -p "是否推送到 Gitee? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push gitee main || git push gitee master || echo "推送失败，请检查远程仓库配置"
        echo "✓ 已推送到 Gitee"
        echo ""
        
        echo ">>> 在服务器上执行以下命令拉取："
        echo "  cd /var/www/my-fullstack-app"
        echo "  git pull gitee main"
        echo ""
    fi
else
    echo "已取消提交"
fi

echo "=========================================="
echo "完成"
echo "=========================================="

