#!/bin/bash
# 修复权限并执行深度修复
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/修复权限并执行深度修复.sh

set -e

echo "=========================================="
echo "修复权限并执行深度修复"
echo "=========================================="
echo ""

cd /var/www/my-fullstack-app

# 1. 修复所有文件权限
echo ">>> 1. 修复文件权限..."
sudo chown -R $(whoami):$(whoami) .
sudo chmod -R 755 .
sudo chmod -R 775 data/
echo "✓ 权限已修复"
echo ""

# 2. 同步代码
echo ">>> 2. 同步代码..."
git fetch gitee main
git reset --hard gitee/main
echo "✓ 代码已同步"
echo ""

# 3. 再次修复权限（确保图片文件可访问）
echo ">>> 3. 确保图片文件权限正确..."
SERVICE_USER=$(ps aux | grep '[u]vicorn' | head -1 | awk '{print $1}' || echo "www-data")
if [ -z "$SERVICE_USER" ] || [ "$SERVICE_USER" = "root" ]; then
    SERVICE_USER=$(systemctl show -p User my-fullstack-app 2>/dev/null | cut -d= -f2 || echo "www-data")
fi

sudo chown -R "$SERVICE_USER:$SERVICE_USER" data/
sudo chmod -R 755 data/
echo "✓ 图片文件权限已修复"
echo ""

# 4. 执行深度修复
echo ">>> 4. 执行深度修复..."
bash scripts/deploy/深度修复-解决无法访问.sh

echo ""
echo "=========================================="
echo "完成！"
echo "=========================================="

