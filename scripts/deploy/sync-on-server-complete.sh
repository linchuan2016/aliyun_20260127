#!/bin/bash
# 在阿里云服务器上直接执行的完整同步脚本
# 使用方法: 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/sync-on-server-complete.sh

set -e  # 遇到错误立即退出

DEPLOY_PATH="/var/www/my-fullstack-app"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "开始同步代码并部署 (时间: $TIMESTAMP)"
echo "=========================================="
echo ""

# 步骤 1: 处理 Git 本地修改
echo ">>> 步骤 1: 处理 Git 本地修改..."
cd $DEPLOY_PATH
if [ -n "$(git status --porcelain)" ]; then
    echo "检测到本地修改，正在保存..."
    git stash push -m "backup-$TIMESTAMP" || true
    echo "本地修改已保存到 stash"
fi
echo "✓ Git 状态检查完成"
echo ""

# 步骤 2: 拉取最新代码
echo ">>> 步骤 2: 从 Gitee 拉取最新代码..."
git fetch gitee main
if [ $? -ne 0 ]; then
    echo "✗ Git fetch 失败，尝试清理后重试..."
    git clean -fd
    git fetch gitee main
fi
git reset --hard gitee/main
echo "✓ 代码拉取成功"
echo "当前提交: $(git log -1 --oneline)"
echo ""

# 步骤 3: 更新后端依赖
echo ">>> 步骤 3: 更新后端依赖..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo "✓ 后端依赖更新完成"
echo ""

# 步骤 4: 初始化/更新数据库
echo ">>> 步骤 4: 初始化/更新数据库..."
python init_db.py 2>&1 || echo "数据库初始化完成（可能已存在）"
echo "✓ 数据库检查完成"
echo ""

# 步骤 4.5: 导入文章数据
echo ">>> 步骤 4.5: 导入文章数据..."
if [ -f "$DEPLOY_PATH/data/articles.json" ]; then
    python import_articles.py
    if [ $? -eq 0 ]; then
        echo "✓ 文章数据导入成功"
    else
        echo "⚠ 文章数据导入失败，但不影响服务启动"
    fi
else
    echo "⚠ data/articles.json 不存在，跳过文章导入"
fi
echo ""

# 步骤 5: 构建前端
echo ">>> 步骤 5: 构建前端..."
cd $DEPLOY_PATH/frontend
export NODE_OPTIONS="--max-old-space-size=2048"
npm install --silent
npm run build
if [ $? -ne 0 ]; then
    echo "✗ 前端构建失败"
    exit 1
fi
echo "✓ 前端构建成功"
echo ""

# 步骤 6: 检查后端服务状态
echo ">>> 步骤 6: 检查后端服务状态..."
if systemctl is-active --quiet my-fullstack-app; then
    echo "后端服务正在运行"
else
    echo "⚠ 后端服务未运行，将尝试启动"
fi
echo ""

# 步骤 7: 重启服务
echo ">>> 步骤 7: 重启服务..."
systemctl daemon-reload
systemctl restart my-fullstack-app
sleep 3
systemctl restart nginx
sleep 2
echo "✓ 服务重启完成"
echo ""

# 步骤 8: 验证服务状态
echo ">>> 步骤 8: 验证服务状态..."
echo "=== 后端服务状态 ==="
systemctl status my-fullstack-app --no-pager -l | head -15
echo ""
echo "=== Nginx 服务状态 ==="
systemctl status nginx --no-pager -l | head -10
echo ""
echo "=== 端口监听检查 ==="
if command -v netstat > /dev/null; then
    netstat -tlnp | grep -E ":(80|8000)" || echo "端口未监听"
elif command -v ss > /dev/null; then
    ss -tlnp | grep -E ":(80|8000)" || echo "端口未监听"
else
    echo "无法检查端口（netstat 和 ss 都不可用）"
fi
echo ""

# 步骤 9: 测试 API 健康检查
echo ">>> 步骤 9: 测试 API 健康检查..."
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ API 健康检查通过 (HTTP $HTTP_CODE)"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "⚠ API 健康检查失败 (HTTP $HTTP_CODE)"
    echo "查看后端日志: journalctl -u my-fullstack-app -n 50 --no-pager"
fi
echo ""

echo "=========================================="
echo "同步完成！"
echo "=========================================="
echo ""
echo "访问地址:"
echo "  HTTP:  http://47.112.29.212"
echo "  HTTPS: https://linchuan.tech"
echo ""
echo "如果遇到问题，可以执行以下命令查看日志:"
echo "  journalctl -u my-fullstack-app -n 100 --no-pager"
echo "  tail -n 50 /var/log/nginx/my-fullstack-app-error.log"
echo ""

