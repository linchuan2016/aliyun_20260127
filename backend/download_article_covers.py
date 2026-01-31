"""
下载文章封面图片到本地
"""
import os
import requests
from urllib.parse import urlparse
from database import SessionLocal
from models import Article

# 封面图片保存目录
COVERS_DIR = os.path.join(os.path.dirname(__file__), "..", "frontend", "public", "article-covers")
os.makedirs(COVERS_DIR, exist_ok=True)

def download_image(url, save_path):
    """下载图片到本地"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Referer': 'https://www.notion.com/',
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
            req.add_header('Referer', 'https://www.notion.com/')
            with urllib.request.urlopen(req, timeout=15) as response:
                with open(save_path, 'wb') as f:
                    f.write(response.read())
                print(f"  Downloaded (using urllib): {save_path}")
                return True
        except Exception as e2:
            print(f"  Also failed with urllib: {e2}")
            return False

def get_filename_from_url(url, article_id):
    """从URL获取文件名"""
    parsed = urlparse(url)
    path = parsed.path
    # 提取文件名
    filename = os.path.basename(path)
    if not filename or '.' not in filename:
        # 如果没有文件名，使用article_id
        filename = f"article_{article_id}.jpg"
    return filename

def download_article_covers():
    """下载所有文章的封面图片"""
    db = SessionLocal()
    try:
        articles = db.query(Article).all()
        print(f"Found {len(articles)} articles")
        
        for article in articles:
            if not article.cover_image:
                print(f"Article '{article.title}' has no cover image URL, skipping...")
                continue
            
            # 如果已经是本地路径，跳过
            if not article.cover_image.startswith('http'):
                print(f"Article '{article.title}' cover is already local: {article.cover_image}")
                continue
            
            print(f"Processing: {article.title}")
            
            # 生成本地文件名
            filename = get_filename_from_url(article.cover_image, article.id)
            local_path = os.path.join(COVERS_DIR, filename)
            
            # 下载图片
            if download_image(article.cover_image, local_path):
                # 更新数据库中的路径为相对路径
                relative_path = f"/article-covers/{filename}"
                article.cover_image = relative_path
                db.commit()
                print(f"  Updated database: {relative_path}")
            else:
                print(f"  Failed to download cover for '{article.title}'")
        
        print("\nDone!")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    print("Downloading article covers...")
    print(f"Covers directory: {COVERS_DIR}")
    download_article_covers()

