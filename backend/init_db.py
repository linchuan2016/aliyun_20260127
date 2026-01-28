"""
数据库初始化脚本
创建表结构并插入初始数据
"""
from database import engine, SessionLocal, Base
from models import Product


def init_db():
    """初始化数据库"""
    # 创建所有表
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    try:
        # 检查是否已有数据
        if db.query(Product).count() > 0:
            print("数据库已有数据，跳过初始化")
            return
        
        # 插入初始数据
        products = [
            Product(
                name="moltbot",
                title="Moltbot - 智能对话机器人",
                description="Moltbot 是一款先进的 AI 对话机器人，基于大语言模型技术，能够理解自然语言并进行智能对话。它可以帮助用户解答问题、提供建议、协助工作，是您的智能助手。",
                features="自然语言理解\n多轮对话支持\n上下文记忆\n多语言支持\n可定制化配置",
                image_url="https://via.placeholder.com/400x300?text=Moltbot",
                order_index=1
            ),
            Product(
                name="notebooklm",
                title="NotebookLM - 智能笔记助手",
                description="NotebookLM 是一个基于 AI 的智能笔记管理工具，能够帮助您整理、分析和理解笔记内容。它可以从您的笔记中提取关键信息，生成摘要，甚至回答关于笔记内容的问题。",
                features="智能笔记整理\n自动摘要生成\n内容问答\n知识图谱构建\n多格式支持",
                image_url="https://via.placeholder.com/400x300?text=NotebookLM",
                order_index=2
            ),
            Product(
                name="manus",
                title="Manus - 智能文档处理",
                description="Manus 是一个强大的文档处理和知识管理系统，能够处理各种格式的文档，提取关键信息，建立知识库。无论是 PDF、Word 还是网页内容，Manus 都能帮您快速理解和整理。",
                features="多格式文档支持\n智能信息提取\n知识库管理\n全文搜索\n文档关联分析",
                image_url="https://via.placeholder.com/400x300?text=Manus",
                order_index=3
            ),
        ]
        
        for product in products:
            db.add(product)
        
        db.commit()
        print(f"成功初始化 {len(products)} 个产品数据")
        
    except Exception as e:
        db.rollback()
        print(f"初始化数据库失败: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    print("开始初始化数据库...")
    init_db()
    print("数据库初始化完成！")

