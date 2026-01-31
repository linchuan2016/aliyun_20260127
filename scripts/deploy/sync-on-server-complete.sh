#!/bin/bash
# 在阿里云服务器上直接执行的完整同步脚本（包含封面图片修复）
# 使用方法: 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/sync-on-server-complete.sh

set -e  # 遇到错误立即退出

DEPLOY_PATH="/var/www/my-fullstack-app"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "开始同步代码并部署 (时间: $TIMESTAMP)"
echo "=========================================="
echo ""

# 步骤 0: 修复 Git 权限问题
echo ">>> 步骤 0: 修复 Git 权限..."
CURRENT_USER=$(whoami)
if [ -d ".git" ]; then
    # 修复 .git 目录权限
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" .git 2>/dev/null || true
    sudo chmod -R 755 .git 2>/dev/null || true
    # 清理锁定文件
    rm -f .git/index.lock .git/FETCH_HEAD.lock 2>/dev/null || true
    # 配置安全目录
    git config --global --add safe.directory "$DEPLOY_PATH" 2>/dev/null || true
    echo "✓ Git 权限已修复"
else
    echo "⚠ .git 目录不存在，跳过权限修复"
fi
echo ""

# 步骤 1: 处理 Git 本地修改
echo ">>> 步骤 1: 处理 Git 本地修改..."
cd $DEPLOY_PATH
# 先清理可能的锁定文件
rm -f .git/index.lock .git/FETCH_HEAD.lock 2>/dev/null || true

if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "检测到本地修改，正在保存..."
    git stash push -m "backup-$TIMESTAMP" 2>/dev/null || {
        echo "⚠ Stash 失败，尝试直接重置..."
        git reset --hard HEAD 2>/dev/null || true
    }
    echo "本地修改已处理"
fi
echo "✓ Git 状态检查完成"
echo ""

# 步骤 2: 拉取最新代码
echo ">>> 步骤 2: 从 Gitee 拉取最新代码..."
# 确保权限正确
sudo chown -R "$CURRENT_USER:$CURRENT_USER" .git 2>/dev/null || true
rm -f .git/FETCH_HEAD.lock 2>/dev/null || true

git fetch gitee main 2>&1
if [ $? -ne 0 ]; then
    echo "✗ Git fetch 失败，尝试修复权限后重试..."
    sudo chown -R "$CURRENT_USER:$CURRENT_USER" .git
    sudo chmod -R 755 .git
    rm -f .git/FETCH_HEAD.lock
    git fetch gitee main 2>&1
fi

git reset --hard gitee/main 2>&1

# 确保图片文件从 Git 中恢复（如果被忽略或删除）
echo "恢复图片文件..."
git checkout gitee/main -- data/book-covers/ data/article-covers/ 2>/dev/null || true

echo "✓ 代码拉取成功"
echo "当前提交: $(git log -1 --oneline 2>/dev/null || echo '无法获取提交信息')"
echo ""

# 步骤 3: 更新后端依赖
echo ">>> 步骤 3: 更新后端依赖..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo "✓ 后端依赖更新完成"
echo ""

# 步骤 4: 修复数据库权限
echo ">>> 步骤 4: 修复数据库权限..."
DATA_DIR="$DEPLOY_PATH/data"
SERVICE_USER=$(ps aux | grep '[u]vicorn' | head -1 | awk '{print $1}' || echo "www-data")
if [ -z "$SERVICE_USER" ] || [ "$SERVICE_USER" = "root" ]; then
    SERVICE_USER=$(systemctl show -p User my-fullstack-app 2>/dev/null | cut -d= -f2 || echo "www-data")
fi

echo "服务用户: $SERVICE_USER"
sudo mkdir -p "$DATA_DIR"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$DATA_DIR"
sudo chmod -R 775 "$DATA_DIR"
echo "✓ 权限已修复"
echo ""

# 步骤 5: 初始化/更新数据库
echo ">>> 步骤 5: 初始化/更新数据库..."
sudo -u "$SERVICE_USER" bash << 'INIT_EOF'
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python3 init_db.py
INIT_EOF

echo "✓ 数据库初始化完成"
echo ""

# 步骤 6: 修复封面图片路径
echo ">>> 步骤 6: 修复封面图片路径..."
sudo -u "$SERVICE_USER" bash << 'UPDATE_EOF'
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python3 update_cover_images.py
UPDATE_EOF

echo "✓ 封面路径已更新"
echo ""

# 步骤 7: 确保图片文件存在
echo ">>> 步骤 7: 检查并确保图片文件存在..."
sudo mkdir -p "$DATA_DIR/article-covers" "$DATA_DIR/book-covers"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$DATA_DIR"

# 首先尝试从 Git 恢复图片文件
echo "从 Git 恢复图片文件..."
cd "$DEPLOY_PATH"
git checkout gitee/main -- data/book-covers/ data/article-covers/ 2>/dev/null || true

# 如果仍然不存在，尝试下载
if [ ! -f "$DATA_DIR/article-covers/Steam.jpg" ]; then
    echo "文章封面不存在，尝试下载..."
    sudo -u "$SERVICE_USER" bash << 'DOWNLOAD_EOF'
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python3 download_article_covers.py
DOWNLOAD_EOF
fi

if [ ! -f "$DATA_DIR/book-covers/s3259913.jpg" ] || [ ! -f "$DATA_DIR/book-covers/s1070959.jpg" ]; then
    echo "书籍封面不存在，尝试下载..."
    sudo -u "$SERVICE_USER" bash << 'DOWNLOAD_EOF'
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python3 download_book_covers.py
DOWNLOAD_EOF
fi

# 验证文件存在
echo "验证图片文件..."
if [ -f "$DATA_DIR/book-covers/s3259913.jpg" ]; then
    echo "  ✓ s3259913.jpg 存在"
else
    echo "  ✗ s3259913.jpg 缺失"
fi
if [ -f "$DATA_DIR/book-covers/s1070959.jpg" ]; then
    echo "  ✓ s1070959.jpg 存在"
else
    echo "  ✗ s1070959.jpg 缺失"
fi
if [ -f "$DATA_DIR/article-covers/Steam.jpg" ]; then
    echo "  ✓ Steam.jpg 存在"
else
    echo "  ✗ Steam.jpg 缺失"
fi

# 确保权限正确
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$DATA_DIR"
sudo chmod -R 755 "$DATA_DIR"

echo "✓ 图片文件检查完成"
echo ""

# 步骤 8: 构建前端
echo ">>> 步骤 8: 构建前端..."
FRONTEND_DIR="$DEPLOY_PATH/frontend"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$FRONTEND_DIR"
sudo chmod -R 755 "$FRONTEND_DIR"

if [ -d "$FRONTEND_DIR/node_modules" ]; then
    sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$FRONTEND_DIR/node_modules"
    sudo chmod -R 755 "$FRONTEND_DIR/node_modules"
fi

cd "$FRONTEND_DIR"

sudo -u "$SERVICE_USER" bash << 'BUILD_EOF'
export NODE_OPTIONS='--max-old-space-size=2048'
npm install --silent
npm run build
BUILD_EOF

if [ $? -eq 0 ]; then
    echo "✓ 前端构建成功"
else
    echo "✗ 前端构建失败"
    exit 1
fi
echo ""

# 步骤 9: 重启服务
echo ">>> 步骤 9: 重启服务..."
systemctl daemon-reload
systemctl restart my-fullstack-app
sleep 5
systemctl restart nginx
sleep 2
echo "✓ 服务重启完成"
echo ""

# 步骤 10: 验证服务状态
echo ">>> 步骤 10: 验证服务状态..."
echo "=== 后端服务状态 ==="
systemctl status my-fullstack-app --no-pager -l | head -15
echo ""
echo "=== Nginx 服务状态 ==="
systemctl status nginx --no-pager -l | head -10
echo ""

# 步骤 11: 测试 API 健康检查
echo ">>> 步骤 11: 测试 API 健康检查..."
sleep 3
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

# 步骤 12: 验证封面图片
echo ">>> 步骤 12: 验证封面图片..."
cd $DEPLOY_PATH/backend
source ../venv/bin/activate

python3 << 'VERIFY_EOF'
from database import SessionLocal
from models import Article, Book
import requests

db = SessionLocal()
try:
    print("=== 文章封面验证 ===")
    articles = db.query(Article).all()
    for article in articles:
        if article.cover_image:
            url = f"http://127.0.0.1:8000{article.cover_image}"
            try:
                r = requests.head(url, timeout=5)
                status = "✓" if r.status_code == 200 else "✗"
                print(f"{status} ID {article.id}: {article.cover_image} (HTTP {r.status_code})")
            except Exception as e:
                print(f"✗ ID {article.id}: {article.cover_image} (错误)")
        else:
            print(f"✗ ID {article.id}: 无封面")
    
    print("")
    print("=== 书籍封面验证 ===")
    books = db.query(Book).all()
    for book in books:
        if book.cover_image:
            url = f"http://127.0.0.1:8000{book.cover_image}"
            try:
                r = requests.head(url, timeout=5)
                status = "✓" if r.status_code == 200 else "✗"
                print(f"{status} ID {book.id}: {book.cover_image} (HTTP {r.status_code})")
            except Exception as e:
                print(f"✗ ID {book.id}: {book.cover_image} (错误)")
        else:
            print(f"✗ ID {book.id}: 无封面")
finally:
    db.close()
VERIFY_EOF

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
