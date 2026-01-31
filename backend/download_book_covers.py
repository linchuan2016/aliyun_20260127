"""
下载书籍封面图片到本地
"""
import os
import requests
from urllib.parse import urlparse
from database import SessionLocal
from models import Book

# 封面图片保存目录
COVERS_DIR = os.path.join(os.path.dirname(__file__), "..", "frontend", "public", "book-covers")
os.makedirs(COVERS_DIR, exist_ok=True)

def download_image(url, save_path):
    """下载图片到本地"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Referer': 'https://book.douban.com/',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
            'Sec-Fetch-Dest': 'image',
            'Sec-Fetch-Mode': 'no-cors',
            'Sec-Fetch-Site': 'cross-site'
        }
        session = requests.Session()
        response = session.get(url, headers=headers, timeout=15, allow_redirects=True)
        response.raise_for_status()
        
        with open(save_path, 'wb') as f:
            f.write(response.content)
        print(f"  Downloaded: {save_path}")
        return True
    except Exception as e:
        print(f"  Error downloading {url}: {e}")
        # 尝试使用备用方法：直接使用urllib
        try:
            import urllib.request
            req = urllib.request.Request(url)
            req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
            req.add_header('Referer', 'https://book.douban.com/')
            with urllib.request.urlopen(req, timeout=15) as response:
                with open(save_path, 'wb') as f:
                    f.write(response.read())
                print(f"  Downloaded (using urllib): {save_path}")
                return True
        except Exception as e2:
            print(f"  Also failed with urllib: {e2}")
            return False

def get_filename_from_url(url, book_id):
    """从URL获取文件名"""
    parsed = urlparse(url)
    path = parsed.path
    # 提取文件名
    filename = os.path.basename(path)
    if not filename or '.' not in filename:
        # 如果没有文件名，使用book_id
        filename = f"book_{book_id}.jpg"
    return filename

def download_book_covers():
    """下载所有书籍的封面图片"""
    db = SessionLocal()
    try:
        books = db.query(Book).all()
        print(f"Found {len(books)} books")
        
        for book in books:
            if not book.cover_image:
                print(f"Book '{book.title}' has no cover image URL, skipping...")
                continue
            
            # 如果已经是本地路径，跳过
            if not book.cover_image.startswith('http'):
                print(f"Book '{book.title}' cover is already local: {book.cover_image}")
                continue
            
            print(f"Processing: {book.title}")
            
            # 生成本地文件名
            filename = get_filename_from_url(book.cover_image, book.id)
            local_path = os.path.join(COVERS_DIR, filename)
            
            # 下载图片
            if download_image(book.cover_image, local_path):
                # 更新数据库中的路径为相对路径
                relative_path = f"/book-covers/{filename}"
                book.cover_image = relative_path
                db.commit()
                print(f"  Updated database: {relative_path}")
            else:
                print(f"  Failed to download cover for '{book.title}'")
        
        print("\nDone!")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    print("Downloading book covers...")
    print(f"Covers directory: {COVERS_DIR}")
    download_book_covers()

