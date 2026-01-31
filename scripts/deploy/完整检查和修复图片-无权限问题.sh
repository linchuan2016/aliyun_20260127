#!/bin/bash
# 完整检查和修复图片问题（无权限问题版本）
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/完整检查和修复图片-无权限问题.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"
DATA_DIR="$DEPLOY_PATH/data"

echo "=========================================="
echo "完整检查和修复图片问题"
echo "=========================================="
echo ""

cd "$DEPLOY_PATH"

# 1. 检查图片文件是否存在
echo ">>> 1. 检查图片文件..."
echo ""

echo "=== 书籍封面 ==="
if [ -f "$DATA_DIR/book-covers/s3259913.jpg" ]; then
    echo "✓ s3259913.jpg 存在"
    ls -lh "$DATA_DIR/book-covers/s3259913.jpg" 2>/dev/null || echo "  文件存在但无法查看详情"
else
    echo "✗ s3259913.jpg 不存在"
fi

if [ -f "$DATA_DIR/book-covers/s1070959.jpg" ]; then
    echo "✓ s1070959.jpg 存在"
    ls -lh "$DATA_DIR/book-covers/s1070959.jpg" 2>/dev/null || echo "  文件存在但无法查看详情"
else
    echo "✗ s1070959.jpg 不存在"
fi

echo ""
echo "=== 文章封面 ==="
if [ -f "$DATA_DIR/article-covers/Steam.jpg" ]; then
    echo "✓ Steam.jpg 存在"
    ls -lh "$DATA_DIR/article-covers/Steam.jpg" 2>/dev/null || echo "  文件存在但无法查看详情"
else
    echo "✗ Steam.jpg 不存在"
fi

echo ""

# 2. 检查文件权限
echo ">>> 2. 检查文件权限..."
SERVICE_USER=$(ps aux | grep '[u]vicorn' | head -1 | awk '{print $1}' || echo "www-data")
if [ -z "$SERVICE_USER" ] || [ "$SERVICE_USER" = "root" ]; then
    SERVICE_USER=$(systemctl show -p User my-fullstack-app 2>/dev/null | cut -d= -f2 || echo "www-data")
fi

echo "服务用户: $SERVICE_USER"
echo "当前用户: $(whoami)"

# 修复权限（使用 sudo 确保有权限）
sudo mkdir -p "$DATA_DIR/article-covers" "$DATA_DIR/book-covers"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$DATA_DIR" 2>/dev/null || sudo chown -R "$(whoami):$(whoami)" "$DATA_DIR"
sudo chmod -R 755 "$DATA_DIR"

echo "✓ 权限已修复"
echo ""

# 3. 如果图片不存在，从 Git 恢复
echo ">>> 3. 从 Git 恢复图片文件..."
cd "$DEPLOY_PATH"

# 确保 Git 权限正确
sudo chown -R "$(whoami):$(whoami)" .git 2>/dev/null || true
sudo chmod -R 755 .git 2>/dev/null || true
rm -f .git/index.lock .git/FETCH_HEAD.lock 2>/dev/null || true

# 从 Git 恢复图片
if [ -d ".git" ]; then
    echo "从 Git 恢复图片文件..."
    git checkout HEAD -- data/book-covers/ data/article-covers/ 2>/dev/null || \
    git checkout gitee/main -- data/book-covers/ data/article-covers/ 2>/dev/null || \
    echo "⚠ 无法从 Git 恢复，将尝试下载"
fi

# 再次检查文件是否存在
if [ ! -f "$DATA_DIR/book-covers/s3259913.jpg" ] || [ ! -f "$DATA_DIR/book-covers/s1070959.jpg" ]; then
    echo "图片文件仍然缺失，尝试下载..."
    cd backend
    source ../venv/bin/activate
    
    # 使用当前用户运行（不需要 sudo）
    python3 download_book_covers.py 2>&1 || {
        echo "⚠ 下载失败，尝试使用 sudo..."
        sudo -u "$SERVICE_USER" bash << 'DOWNLOAD_EOF'
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python3 download_book_covers.py
DOWNLOAD_EOF
    }
    
    deactivate
    cd ..
fi

if [ ! -f "$DATA_DIR/article-covers/Steam.jpg" ]; then
    echo "文章封面缺失，尝试下载..."
    cd backend
    source ../venv/bin/activate
    
    python3 download_article_covers.py 2>&1 || {
        echo "⚠ 下载失败，尝试使用 sudo..."
        sudo -u "$SERVICE_USER" bash << 'DOWNLOAD_EOF'
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python3 download_article_covers.py
DOWNLOAD_EOF
    }
    
    deactivate
    cd ..
fi

# 再次修复权限
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$DATA_DIR" 2>/dev/null || sudo chown -R "$(whoami):$(whoami)" "$DATA_DIR"
sudo chmod -R 755 "$DATA_DIR"

echo ""

# 4. 检查数据库中的路径
echo ">>> 4. 检查并修复数据库路径..."
cd backend
source ../venv/bin/activate

python3 << 'CHECK_DB_EOF'
from database import SessionLocal
from models import Article, Book
import os

db = SessionLocal()
try:
    updated = 0
    
    print("=== 检查书籍封面路径 ===")
    books = db.query(Book).all()
    for book in books:
        cover = book.cover_image or "(None)"
        print(f"ID {book.id}: {cover}")
        
        if book.cover_image:
            # 修复 .ing 为 .jpg
            if '.ing' in book.cover_image:
                book.cover_image = book.cover_image.replace('.ing', '.jpg')
                updated += 1
                print(f"  修复: {book.cover_image}")
            
            # 确保路径正确
            if 's3259913' in book.cover_image:
                if book.cover_image != "/data/book-covers/s3259913.jpg":
                    book.cover_image = "/data/book-covers/s3259913.jpg"
                    updated += 1
                    print(f"  修复为: {book.cover_image}")
            elif 's1070959' in book.cover_image:
                if book.cover_image != "/data/book-covers/s1070959.jpg":
                    book.cover_image = "/data/book-covers/s1070959.jpg"
                    updated += 1
                    print(f"  修复为: {book.cover_image}")
    
    print("")
    print("=== 检查文章封面路径 ===")
    articles = db.query(Article).all()
    for article in articles:
        cover = article.cover_image or "(None)"
        print(f"ID {article.id}: {cover}")
        
        if article.cover_image and 'Steam' in article.cover_image:
            if article.cover_image != "/data/article-covers/Steam.jpg":
                article.cover_image = "/data/article-covers/Steam.jpg"
                updated += 1
                print(f"  修复为: {article.cover_image}")
    
    if updated > 0:
        db.commit()
        print(f"\n✓ 修复了 {updated} 条记录")
    else:
        print("\n✓ 数据库路径正常")
finally:
    db.close()
CHECK_DB_EOF

deactivate
cd ..

echo ""

# 5. 检查静态文件服务配置
echo ">>> 5. 检查静态文件服务配置..."
if grep -q "app.mount.*data" backend/main.py; then
    echo "✓ 静态文件服务已配置"
    grep "app.mount.*data" backend/main.py
else
    echo "✗ 静态文件服务未配置"
fi
echo ""

# 6. 测试图片 URL
echo ">>> 6. 测试图片 URL..."
cd backend
source ../venv/bin/activate

python3 << 'TEST_URL_EOF'
import requests
import os
from database import SessionLocal
from models import Article, Book

db = SessionLocal()
try:
    print("=== 测试书籍封面 URL ===")
    books = db.query(Book).all()
    for book in books:
        if book.cover_image:
            # 检查文件是否存在
            file_path = book.cover_image.replace('/data/', '/var/www/my-fullstack-app/data/')
            file_exists = os.path.exists(file_path)
            
            # 测试 URL
            url = f"http://127.0.0.1:8000{book.cover_image}"
            try:
                r = requests.head(url, timeout=5)
                if r.status_code == 200:
                    print(f"✓ ID {book.id}: {book.cover_image}")
                    print(f"  文件存在: {'是' if file_exists else '否'}")
                    print(f"  URL 可访问: 是 (HTTP {r.status_code})")
                else:
                    print(f"✗ ID {book.id}: {book.cover_image}")
                    print(f"  文件存在: {'是' if file_exists else '否'}")
                    print(f"  URL 可访问: 否 (HTTP {r.status_code})")
            except Exception as e:
                print(f"✗ ID {book.id}: {book.cover_image}")
                print(f"  文件存在: {'是' if file_exists else '否'}")
                print(f"  URL 错误: {str(e)[:50]}")
    
    print("")
    print("=== 测试文章封面 URL ===")
    articles = db.query(Article).all()
    for article in articles:
        if article.cover_image:
            file_path = article.cover_image.replace('/data/', '/var/www/my-fullstack-app/data/')
            file_exists = os.path.exists(file_path)
            
            url = f"http://127.0.0.1:8000{article.cover_image}"
            try:
                r = requests.head(url, timeout=5)
                if r.status_code == 200:
                    print(f"✓ ID {article.id}: {article.cover_image}")
                    print(f"  文件存在: {'是' if file_exists else '否'}")
                    print(f"  URL 可访问: 是 (HTTP {r.status_code})")
                else:
                    print(f"✗ ID {article.id}: {article.cover_image}")
                    print(f"  文件存在: {'是' if file_exists else '否'}")
                    print(f"  URL 可访问: 否 (HTTP {r.status_code})")
            except Exception as e:
                print(f"✗ ID {article.id}: {article.cover_image}")
                print(f"  文件存在: {'是' if file_exists else '否'}")
                print(f"  URL 错误: {str(e)[:50]}")
finally:
    db.close()
TEST_URL_EOF

deactivate
cd ..

echo ""

# 7. 重启服务
echo ">>> 7. 重启服务..."
sudo systemctl restart my-fullstack-app
sleep 3
sudo systemctl restart nginx
sleep 2

echo "✓ 服务已重启"
echo ""

# 8. 最终验证
echo ">>> 8. 最终验证..."
sleep 3

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    echo "✓ 后端 API 正常 (HTTP $HTTP_CODE)"
else
    echo "✗ 后端 API 异常 (HTTP $HTTP_CODE)"
fi

echo ""
echo "=========================================="
echo "检查完成！"
echo "=========================================="
echo ""
echo "如果图片仍然不显示，请检查："
echo "1. 浏览器控制台的错误信息"
echo "2. 后端日志: sudo journalctl -u my-fullstack-app -n 50 --no-pager"
echo "3. Nginx 日志: sudo tail -n 50 /var/log/nginx/error.log"
echo "4. 直接访问图片 URL:"
echo "   http://47.112.29.212/data/book-covers/s3259913.jpg"
echo "   http://47.112.29.212/data/book-covers/s1070959.jpg"
echo "   http://47.112.29.212/data/article-covers/Steam.jpg"
echo ""

