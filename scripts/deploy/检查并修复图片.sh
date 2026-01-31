#!/bin/bash
# 检查并修复图片文件问题
# 在服务器上执行: bash /var/www/my-fullstack-app/scripts/deploy/检查并修复图片.sh

set -e

echo "=========================================="
echo "检查并修复图片文件"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"
DATA_DIR="$DEPLOY_PATH/data"

cd "$DEPLOY_PATH"

# 1. 检查图片文件是否存在
echo ">>> 1. 检查图片文件..."
echo ""

echo "=== 书籍封面 ==="
if [ -f "$DATA_DIR/book-covers/s3259913.jpg" ]; then
    echo "✓ s3259913.jpg 存在"
    ls -lh "$DATA_DIR/book-covers/s3259913.jpg"
else
    echo "✗ s3259913.jpg 不存在"
fi

if [ -f "$DATA_DIR/book-covers/s1070959.jpg" ]; then
    echo "✓ s1070959.jpg 存在"
    ls -lh "$DATA_DIR/book-covers/s1070959.jpg"
else
    echo "✗ s1070959.jpg 不存在"
fi

echo ""
echo "=== 文章封面 ==="
if [ -f "$DATA_DIR/article-covers/Steam.jpg" ]; then
    echo "✓ Steam.jpg 存在"
    ls -lh "$DATA_DIR/article-covers/Steam.jpg"
else
    echo "✗ Steam.jpg 不存在"
fi

echo ""

# 2. 检查数据库中的路径
echo ">>> 2. 检查数据库中的路径..."
cd backend
source ../venv/bin/activate

python3 << 'CHECK_DB_EOF'
from database import SessionLocal
from models import Article, Book

db = SessionLocal()
try:
    print("=== 书籍封面路径 ===")
    books = db.query(Book).all()
    for book in books:
        cover = book.cover_image or "(None)"
        print(f"ID {book.id} ({book.title[:30]}): {cover}")
        if cover and cover != "(None)":
            # 检查路径是否正确
            if '.ing' in cover:
                print(f"  ⚠ 警告：路径包含 .ing，应该是 .jpg")
            if not cover.startswith('/data/'):
                print(f"  ⚠ 警告：路径不是 /data/ 开头")
    
    print("")
    print("=== 文章封面路径 ===")
    articles = db.query(Article).all()
    for article in articles:
        cover = article.cover_image or "(None)"
        print(f"ID {article.id} ({article.title[:30]}): {cover}")
        if cover and cover != "(None)":
            if not cover.startswith('/data/'):
                print(f"  ⚠ 警告：路径不是 /data/ 开头")
finally:
    db.close()
CHECK_DB_EOF

echo ""

# 3. 修复数据库路径（如果有问题）
echo ">>> 3. 修复数据库路径..."
python3 << 'FIX_DB_EOF'
from database import SessionLocal
from models import Article, Book

db = SessionLocal()
try:
    updated = 0
    
    # 修复书籍封面路径
    books = db.query(Book).all()
    for book in books:
        if book.cover_image:
            # 修复 .ing 为 .jpg
            if '.ing' in book.cover_image:
                book.cover_image = book.cover_image.replace('.ing', '.jpg')
                updated += 1
                print(f"修复书籍 ID {book.id}: {book.cover_image}")
            # 确保路径正确
            if 's3259913' in book.cover_image and not book.cover_image.endswith('.jpg'):
                book.cover_image = "/data/book-covers/s3259913.jpg"
                updated += 1
                print(f"修复书籍 ID {book.id}: {book.cover_image}")
            elif 's1070959' in book.cover_image and not book.cover_image.endswith('.jpg'):
                book.cover_image = "/data/book-covers/s1070959.jpg"
                updated += 1
                print(f"修复书籍 ID {book.id}: {book.cover_image}")
    
    # 修复文章封面路径
    articles = db.query(Article).all()
    for article in articles:
        if article.cover_image and 'Steam' in article.cover_image:
            if not article.cover_image.endswith('.jpg'):
                article.cover_image = "/data/article-covers/Steam.jpg"
                updated += 1
                print(f"修复文章 ID {article.id}: {article.cover_image}")
    
    if updated > 0:
        db.commit()
        print(f"\n✓ 修复了 {updated} 条记录")
    else:
        print("\n✓ 数据库路径正常，无需修复")
finally:
    db.close()
FIX_DB_EOF

echo ""

# 4. 如果图片文件不存在，从 Git 同步或下载
echo ">>> 4. 确保图片文件存在..."

# 检查 Git 中是否有图片文件
if [ -d ".git" ]; then
    echo "从 Git 检查图片文件..."
    git ls-files data/book-covers/ data/article-covers/ | while read file; do
        if [ ! -f "$file" ]; then
            echo "从 Git 恢复: $file"
            git checkout "$file" 2>/dev/null || echo "  ⚠ 无法从 Git 恢复，将尝试下载"
        fi
    done
fi

# 如果仍然不存在，尝试下载
if [ ! -f "$DATA_DIR/book-covers/s3259913.jpg" ] || [ ! -f "$DATA_DIR/book-covers/s1070959.jpg" ]; then
    echo "下载缺失的书籍封面..."
    python3 download_book_covers.py
fi

if [ ! -f "$DATA_DIR/article-covers/Steam.jpg" ]; then
    echo "下载缺失的文章封面..."
    python3 download_article_covers.py
fi

echo ""

# 5. 检查文件权限
echo ">>> 5. 检查文件权限..."
SERVICE_USER=$(ps aux | grep '[u]vicorn' | head -1 | awk '{print $1}' || echo "www-data")
if [ -z "$SERVICE_USER" ] || [ "$SERVICE_USER" = "root" ]; then
    SERVICE_USER=$(systemctl show -p User my-fullstack-app 2>/dev/null | cut -d= -f2 || echo "www-data")
fi

echo "服务用户: $SERVICE_USER"
sudo chown -R "$SERVICE_USER:$SERVICE_USER" "$DATA_DIR"
sudo chmod -R 755 "$DATA_DIR"
echo "✓ 权限已修复"

echo ""

# 6. 测试图片 URL
echo ">>> 6. 测试图片 URL..."
python3 << 'TEST_URL_EOF'
import requests
from database import SessionLocal
from models import Article, Book

db = SessionLocal()
try:
    print("=== 测试书籍封面 URL ===")
    books = db.query(Book).all()
    for book in books:
        if book.cover_image:
            url = f"http://127.0.0.1:8000{book.cover_image}"
            try:
                r = requests.head(url, timeout=5)
                if r.status_code == 200:
                    print(f"✓ ID {book.id}: {book.cover_image} (HTTP {r.status_code})")
                else:
                    print(f"✗ ID {book.id}: {book.cover_image} (HTTP {r.status_code})")
            except Exception as e:
                print(f"✗ ID {book.id}: {book.cover_image} (错误: {str(e)[:50]})")
    
    print("")
    print("=== 测试文章封面 URL ===")
    articles = db.query(Article).all()
    for article in articles:
        if article.cover_image:
            url = f"http://127.0.0.1:8000{article.cover_image}"
            try:
                r = requests.head(url, timeout=5)
                if r.status_code == 200:
                    print(f"✓ ID {article.id}: {article.cover_image} (HTTP {r.status_code})")
                else:
                    print(f"✗ ID {article.id}: {article.cover_image} (HTTP {r.status_code})")
            except Exception as e:
                print(f"✗ ID {article.id}: {article.cover_image} (错误: {str(e)[:50]})")
finally:
    db.close()
TEST_URL_EOF

echo ""
echo "=========================================="
echo "检查完成！"
echo "=========================================="
echo ""
echo "如果图片仍然不显示，请："
echo "1. 检查浏览器控制台的错误信息"
echo "2. 确认后端服务正在运行: sudo systemctl status my-fullstack-app"
echo "3. 确认静态文件服务配置正确（backend/main.py 中的 app.mount）"
echo "4. 重启后端服务: sudo systemctl restart my-fullstack-app"
echo ""

