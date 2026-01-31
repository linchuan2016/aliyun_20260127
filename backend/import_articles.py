"""
从 JSON 文件导入文章数据
用于从 Git 仓库同步文章内容到数据库
"""
import json
import os
from datetime import datetime
from database import SessionLocal
from models import Article


def import_articles(input_file="data/articles.json", update_existing=True):
    """
    从 JSON 文件导入文章
    
    Args:
        input_file: JSON 文件路径
        update_existing: 如果文章已存在（根据标题和发布时间判断），是否更新
    """
    db = SessionLocal()
    try:
        # 检查文件是否存在
        if not os.path.exists(input_file):
            print(f"文件不存在: {input_file}")
            return 0
        
        # 读取 JSON 文件
        with open(input_file, 'r', encoding='utf-8') as f:
            articles_data = json.load(f)
        
        if not articles_data:
            print("JSON 文件中没有文章数据")
            return 0
        
        imported_count = 0
        updated_count = 0
        skipped_count = 0
        
        for article_data in articles_data:
            try:
                # 解析发布时间
                publish_date_str = article_data.get('publish_date')
                if publish_date_str:
                    if 'T' in publish_date_str:
                        publish_date = datetime.fromisoformat(publish_date_str.replace('Z', '+00:00'))
                    else:
                        publish_date = datetime.fromisoformat(publish_date_str)
                else:
                    print(f"警告: 文章 '{article_data.get('title')}' 没有发布时间，跳过")
                    skipped_count += 1
                    continue
                
                # 检查文章是否已存在（根据标题和发布时间）
                existing_article = db.query(Article).filter(
                    Article.title == article_data.get('title'),
                    Article.publish_date == publish_date
                ).first()
                
                if existing_article:
                    if update_existing:
                        # 更新现有文章
                        existing_article.author = article_data.get('author', existing_article.author)
                        existing_article.original_url = article_data.get('original_url')
                        existing_article.category = article_data.get('category')
                        existing_article.content = article_data.get('content')
                        existing_article.excerpt = article_data.get('excerpt')
                        # updated_at 会自动更新
                        updated_count += 1
                        print(f"更新文章: {article_data.get('title')}")
                    else:
                        skipped_count += 1
                        print(f"跳过已存在的文章: {article_data.get('title')}")
                else:
                    # 创建新文章
                    new_article = Article(
                        title=article_data.get('title'),
                        publish_date=publish_date,
                        author=article_data.get('author', ''),
                        original_url=article_data.get('original_url'),
                        category=article_data.get('category'),
                        content=article_data.get('content'),
                        excerpt=article_data.get('excerpt')
                    )
                    db.add(new_article)
                    imported_count += 1
                    print(f"导入文章: {article_data.get('title')}")
                    
            except Exception as e:
                print(f"处理文章 '{article_data.get('title')}' 时出错: {e}")
                continue
        
        # 提交更改
        db.commit()
        
        print(f"\n导入完成！")
        print(f"  新导入: {imported_count} 篇")
        print(f"  更新: {updated_count} 篇")
        print(f"  跳过: {skipped_count} 篇")
        print(f"  总计: {imported_count + updated_count + skipped_count} 篇")
        
        return imported_count + updated_count
        
    except Exception as e:
        db.rollback()
        print(f"导入文章失败: {e}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    # 默认从项目根目录的 data 文件夹读取
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    input_path = os.path.join(project_root, "data", "articles.json")
    
    print("开始导入文章数据...")
    count = import_articles(input_path, update_existing=True)
    print(f"导入完成！共处理 {count} 篇文章")

