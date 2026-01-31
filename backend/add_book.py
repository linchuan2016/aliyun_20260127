"""
添加书籍数据脚本
"""
from database import SessionLocal
from models import Book
from datetime import datetime

def add_book(title, cover_image, author, publish_date, description=None):
    """添加书籍"""
    db = SessionLocal()
    try:
        # 检查是否已存在
        existing = db.query(Book).filter(Book.title == title).first()
        if existing:
            print(f"Book '{title}' already exists, skipping...")
            print(f"  Author: {existing.author}")
            print(f"  Publish Date: {existing.publish_date}")
            return
        
        # 创建新书籍
        book = Book(
            title=title,
            cover_image=cover_image,
            author=author,
            publish_date=publish_date,
            description=description
        )
        db.add(book)
        db.commit()
        db.refresh(book)
        print(f"Success! Book '{title}' added successfully!")
        print(f"  ID: {book.id}")
        print(f"  Title: {book.title}")
        print(f"  Author: {book.author}")
        print(f"  Publish Date: {book.publish_date}")
        print(f"  Cover: {book.cover_image}")
    except Exception as e:
        db.rollback()
        print(f"Error: Failed to add book '{title}': {e}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("Adding books...")
    
    # 添加《异类》
    add_book(
        title="异类",
        cover_image="https://img3.doubanio.com/view/subject/l/public/s3259913.jpg",
        author="马尔科姆·格拉德威尔（Malcolm Gladwell）",
        publish_date=datetime(2009, 4, 1),
        description="在《异类》一书中，格拉德威尔对社会中那些成功人士进行的分析，让读者看到了一连串颇感意外的统计结果。这本书要告诉读者的是：如果没有机遇和文化、环境因素，即便是智商超过爱因斯坦，也只能做一份平庸的工作。"
    )
    
    # 添加《枪炮、病菌与钢铁：人类社会的命运》
    add_book(
        title="枪炮、病菌与钢铁：人类社会的命运",
        cover_image="https://img3.doubanio.com/view/subject/l/public/s1070959.jpg",
        author="贾雷德·戴蒙德（Jared Diamond）",
        publish_date=datetime(2000, 8, 1),
        description="为什么是欧亚大陆人征服、赶走或大批杀死印第安人、澳大利亚人和非洲人，而不是相反？为什么小麦和玉米、牛和猪以及现代世界的其他一些“了不起的”作物和牲畜出现在这些特定地区，而不是其他地区？在这部开创性的著作中，演化生物学家贾雷德·戴蒙德揭示了事实上有助于形成历史最广泛模式的环境因素，从而以震撼人心的力量摧毁了以种族主义为基础的人类史理论。"
    )
    
    print("Done!")

