#!/bin/bash
# 在阿里云服务器上直接执行的完整同步命令
# 使用方法: 复制以下所有命令到服务器终端执行

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "开始同步代码到阿里云服务器"
echo "时间: $TIMESTAMP"
echo "=========================================="
echo ""

# 步骤 1: 处理 Git 本地修改
echo ">>> 步骤 1: 处理 Git 本地修改..."
cd $DEPLOY_PATH
if [ -n "$(git status --porcelain)" ]; then
    echo "检测到本地修改，正在保存..."
    git stash push -m "backup-$TIMESTAMP" 2>/dev/null || true
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

# 步骤 3: 检查关键文件
echo ">>> 步骤 3: 检查关键文件..."
KEY_FILES=(
    "backend/main.py"
    "backend/database.py"
    "backend/models.py"
    "backend/schemas.py"
    "backend/auth.py"
    "frontend/src/main.js"
    "frontend/src/router/index.js"
    "frontend/vite.config.js"
)

MISSING_FILES=0
for file in "${KEY_FILES[@]}"; do
    if [ -f "$DEPLOY_PATH/$file" ]; then
        echo "✓ $file 存在"
    else
        echo "✗ $file 缺失"
        MISSING_FILES=$((MISSING_FILES + 1))
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo "⚠ 警告: 有 $MISSING_FILES 个关键文件缺失"
else
    echo "✓ 所有关键文件都存在"
fi
echo ""

# 步骤 4: 更新后端依赖
echo ">>> 步骤 4: 更新后端依赖..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo "✓ 后端依赖更新完成"
echo ""

# 步骤 5: 初始化/更新数据库
echo ">>> 步骤 5: 初始化/更新数据库..."
python init_db.py 2>&1 || echo "数据库初始化完成（可能已存在）"
echo "✓ 数据库检查完成"
echo ""

# 步骤 6: 构建前端
echo ">>> 步骤 6: 构建前端..."
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

# 步骤 7: 检查服务配置
echo ">>> 步骤 7: 检查服务配置..."
if [ -f "/etc/systemd/system/my-fullstack-app.service" ]; then
    echo "✓ systemd 服务文件存在"
else
    echo "✗ systemd 服务文件不存在"
fi
echo ""

# 步骤 8: 重启服务
echo ">>> 步骤 8: 重启服务..."
systemctl daemon-reload
systemctl restart my-fullstack-app
sleep 3
systemctl restart nginx
sleep 2
echo "✓ 服务重启完成"
echo ""

# 步骤 9: 验证服务状态
echo ">>> 步骤 9: 验证服务状态..."
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
fi
echo ""

# 步骤 10: 测试 API
echo ">>> 步骤 10: 测试 API..."
sleep 2
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ 后端 API 正常 (HTTP $HTTP_CODE)"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "✗ 后端 API 异常 (HTTP $HTTP_CODE)"
    echo "查看日志: journalctl -u my-fullstack-app -n 50 --no-pager"
fi
echo ""

# 步骤 11: 测试通过 Nginx 访问
echo ">>> 步骤 11: 测试通过 Nginx 访问..."
HTTP_CODE_NGINX=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1/api/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE_NGINX" = "200" ]; then
    echo "✓ Nginx 代理正常 (HTTP $HTTP_CODE_NGINX)"
else
    echo "✗ Nginx 代理失败 (HTTP $HTTP_CODE_NGINX)"
    echo "检查 Nginx 日志: tail -n 30 /var/log/nginx/error.log"
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

