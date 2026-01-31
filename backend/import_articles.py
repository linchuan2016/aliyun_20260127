"""
从 JSON 文件导入文章数据
用于从 Git 仓库同步文章内容到数据库
"""
import json
import os
import re
from datetime import datetime
from database import SessionLocal
from models import Article


def parse_iso_date(date_str):
    """
    解析 ISO 格式日期字符串，兼容 Python 3.6 及以下版本
    """
    if not date_str:
        return None
    
    try:
        # Python 3.7+ 使用 fromisoformat
        if hasattr(datetime, 'fromisoformat'):
            # 处理时区信息
            if 'Z' in date_str:
                date_str = date_str.replace('Z', '+00:00')
            elif date_str.endswith('+00:00'):
                pass
            elif '+' in date_str or date_str.count('-') > 2:
                # 有时区信息
                pass
            return datetime.fromisoformat(date_str)
        else:
            # Python 3.6 及以下版本使用 strptime
            # 移除时区信息（Z 或 +00:00）
            date_str_clean = re.sub(r'[Z\+].*$', '', date_str)
            
            # 尝试不同的日期格式
            formats = [
                '%Y-%m-%dT%H:%M:%S',      # 2025-12-23T00:00:00
                '%Y-%m-%dT%H:%M:%S.%f',   # 2025-12-23T00:00:00.000000
                '%Y-%m-%d',               # 2025-12-23
            ]
            
            for fmt in formats:
                try:
                    return datetime.strptime(date_str_clean, fmt)
                except ValueError:
                    continue
            
            # 如果所有格式都失败，返回当前时间
            print(f"警告: 无法解析日期 '{date_str}'，使用当前时间")
            return datetime.now()
    except Exception as e:
        print(f"警告: 解析日期 '{date_str}' 时出错: {e}，使用当前时间")
        return datetime.now()


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
                    publish_date = parse_iso_date(publish_date_str)
                    if not publish_date:
                        print(f"警告: 文章 '{article_data.get('title')}' 发布时间解析失败，跳过")
                        skipped_count += 1
                        continue
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

