#!/bin/bash
# 在阿里云服务器上直接从 Gitee 同步代码
# 使用方法: 复制以下所有命令到服务器终端执行，或执行: bash /var/www/my-fullstack-app/scripts/deploy/sync-on-server-complete.sh

set -e  # 遇到错误立即退出

DEPLOY_PATH="/var/www/my-fullstack-app"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "从 Gitee 同步代码并部署 (时间: $TIMESTAMP)"
echo "=========================================="
echo ""

# 步骤 1: 处理 Git 本地修改
echo ">>> 步骤 1: 处理 Git 本地修改..."
cd $DEPLOY_PATH
if [ -n "$(git status --porcelain)" ]; then
    echo "检测到本地修改，正在保存到stash..."
    git stash push -m "backup-$TIMESTAMP" || true
    echo "✓ 本地修改已保存"
fi
echo "✓ Git 状态检查完成"
echo ""

# 步骤 2: 从 Gitee 拉取最新代码
echo ">>> 步骤 2: 从 Gitee 拉取最新代码..."
git fetch gitee main || {
    echo "✗ Git fetch 失败，尝试重新配置..."
    git remote remove gitee 2>/dev/null || true
    git remote add gitee https://gitee.com/linchuan2020/aliyun_20260127.git || true
    git fetch gitee main
}
git reset --hard gitee/main
echo "✓ 代码拉取成功"
echo "当前提交: $(git log -1 --oneline)"
echo ""

# 步骤 3: 更新后端依赖
echo ">>> 步骤 3: 更新后端依赖..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate || {
    echo "✗ 虚拟环境激活失败，请检查venv目录"
    exit 1
}
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo "✓ 后端依赖更新完成"
echo ""

# 步骤 4: 初始化/更新数据库
echo ">>> 步骤 4: 初始化/更新数据库..."
python init_db.py 2>&1 || echo "数据库初始化完成（可能已存在）"
echo "✓ 数据库检查完成"
echo ""

# 步骤 5: 导入文章数据（如果存在）
echo ">>> 步骤 5: 导入文章数据..."
if [ -f "$DEPLOY_PATH/data/articles.json" ]; then
    python import_articles.py 2>&1 || echo "文章导入完成（可能已存在）"
    echo "✓ 文章数据检查完成"
else
    echo "⚠  articles.json 文件不存在，跳过文章导入"
fi
echo ""

# 步骤 6: 构建前端
echo ">>> 步骤 6: 构建前端..."
cd $DEPLOY_PATH/frontend
export NODE_OPTIONS='--max-old-space-size=2048'
npm install --silent
npm run build
echo "✓ 前端构建完成"
echo ""

# 步骤 7: 重启服务
echo ">>> 步骤 7: 重启服务..."
systemctl daemon-reload
systemctl restart my-fullstack-app || {
    echo "✗ 后端服务重启失败，检查日志..."
    journalctl -u my-fullstack-app -n 20 --no-pager
    exit 1
}
sleep 5  # 等待服务启动
systemctl restart nginx
sleep 2
echo "✓ 服务重启完成"
echo ""

# 步骤 8: 检查服务状态
echo ">>> 步骤 8: 检查服务状态..."
echo "--- 后端服务状态 ---"
systemctl status my-fullstack-app --no-pager -l | head -15
echo ""
echo "--- Nginx 服务状态 ---"
systemctl status nginx --no-pager -l | head -10
echo ""

# 步骤 9: 测试 API
echo ">>> 步骤 9: 测试 API..."
sleep 2
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ API 健康检查通过"
else
    echo "✗ API 健康检查失败，请检查后端服务日志"
    journalctl -u my-fullstack-app -n 30 --no-pager
    exit 1
fi
echo ""

echo "=========================================="
echo "同步完成！"
echo "=========================================="
echo "访问地址:"
echo "  HTTP:  http://47.112.29.212"
echo "  HTTPS: https://linchuan.tech"
echo ""

