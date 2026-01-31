"""
导出文章数据到 JSON 文件
用于将文章内容同步到 Git 仓库
"""
import json
import os
from datetime import datetime
from database import SessionLocal
from models import Article


def export_articles(output_file="data/articles.json"):
    """导出所有文章到 JSON 文件"""
    db = SessionLocal()
    try:
        # 获取所有文章
        articles = db.query(Article).order_by(Article.publish_date.desc()).all()
        
        # 转换为字典列表
        articles_data = []
        for article in articles:
            article_dict = article.to_dict()
            articles_data.append(article_dict)
        
        # 确保输出目录存在
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        
        # 写入 JSON 文件
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(articles_data, f, ensure_ascii=False, indent=2)
        
        print(f"成功导出 {len(articles_data)} 篇文章到 {output_file}")
        return len(articles_data)
        
    except Exception as e:
        print(f"导出文章失败: {e}")
        import traceback
        traceback.print_exc()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    # 默认导出到项目根目录的 data 文件夹
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    output_path = os.path.join(project_root, "data", "articles.json")
    
    print("开始导出文章数据...")
    count = export_articles(output_path)
    print(f"导出完成！共 {count} 篇文章")

