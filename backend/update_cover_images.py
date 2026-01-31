"""
更新数据库中的封面图片路径为本地路径
用于修复服务器上的封面图片显示问题
"""
from database import SessionLocal
from models import Article, Book

def update_cover_images():
    """更新封面图片路径"""
    db = SessionLocal()
    
    try:
        print("=" * 50)
        print("更新封面图片路径")
        print("=" * 50)
        print()
        
        # 更新书籍封面
        print(">>> 更新书籍封面...")
        books = db.query(Book).all()
        updated_books = 0
        
        for book in books:
            # 更新旧路径格式
            if book.cover_image:
                # 如果是旧路径格式，更新为新路径
                if book.cover_image.startswith('/book-covers/'):
                    book.cover_image = book.cover_image.replace('/book-covers/', '/data/book-covers/')
                    updated_books += 1
                # 如果是外部URL，改为本地路径
                elif book.cover_image.startswith('http'):
                    if 's3259913' in book.cover_image:
                        book.cover_image = "/data/book-covers/s3259913.jpg"
                        updated_books += 1
                    elif 's1070959' in book.cover_image:
                        book.cover_image = "/data/book-covers/s1070959.jpg"
                        updated_books += 1
        
        if updated_books > 0:
            db.commit()
            print(f"[OK] 更新了 {updated_books} 本书的封面路径")
        else:
            print("[OK] 书籍封面路径已是最新")
        
        # 更新文章封面
        print()
        print(">>> 更新文章封面...")
        articles = db.query(Article).all()
        updated_articles = 0
        
        for article in articles:
            # 更新旧路径格式
            if article.cover_image:
                # 如果是旧路径格式，更新为新路径
                if article.cover_image.startswith('/article-covers/'):
                    article.cover_image = article.cover_image.replace('/article-covers/', '/data/article-covers/')
                    updated_articles += 1
                elif article.cover_image.startswith('/book-covers/'):
                    article.cover_image = article.cover_image.replace('/book-covers/', '/data/book-covers/')
                    updated_articles += 1
            # 如果文章没有封面，设置默认封面
            elif not article.cover_image:
                if 'steam' in article.title.lower() or 'steel' in article.title.lower() or '无限心智' in article.title:
                    article.cover_image = "/data/article-covers/Steam.jpg"
                    updated_articles += 1
        
        if updated_articles > 0:
            db.commit()
            print(f"[OK] 更新了 {updated_articles} 篇文章的封面路径")
        else:
            print("[OK] 文章封面路径已是最新")
        
        print()
        print("=" * 50)
        print("[OK] 封面图片路径更新完成")
        print("=" * 50)
        return True
        
    except Exception as e:
        db.rollback()
        print(f"[ERROR] 错误: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    update_cover_images()

