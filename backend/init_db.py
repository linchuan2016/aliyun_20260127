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
                title="Moltbot",
                description="AI 智能对话机器人，支持自然语言理解和多轮对话。",
                features="自然语言理解\n多轮对话\n智能助手",
                image_url="https://www.google.com/s2/favicons?domain=moltbot.com&sz=128",
                official_url="https://moltbot.com",
                order_index=1
            ),
            Product(
                name="notebooklm",
                title="NotebookLM",
                description="Google 的 AI 笔记助手，帮助整理和分析笔记内容。",
                features="智能笔记\n自动摘要\n内容问答",
                image_url="https://www.google.com/s2/favicons?domain=notebooklm.google.com&sz=128",
                official_url="https://notebooklm.google.com",
                order_index=2
            ),
            Product(
                name="manus",
                title="Manus",
                description="智能文档处理系统，支持多格式文档和信息提取。",
                features="文档处理\n信息提取\n知识库",
                image_url="https://www.google.com/s2/favicons?domain=manus.ai&sz=128",
                official_url="https://manus.ai",
                order_index=3
            ),
            Product(
                name="cursor",
                title="Cursor",
                description="AI 驱动的代码编辑器，提升编程效率。",
                features="AI 编程\n代码补全\n智能提示",
                image_url="https://www.google.com/s2/favicons?domain=cursor.sh&sz=128",
                official_url="https://cursor.sh",
                order_index=4
            ),
            Product(
                name="toolify",
                title="Toolify.ai",
                description="AI 工具聚合平台，发现和比较各种 AI 工具。",
                features="工具聚合\nAI 搜索\n工具比较",
                image_url="https://www.google.com/s2/favicons?domain=toolify.ai&sz=128",
                official_url="https://toolify.ai",
                order_index=5
            ),
            Product(
                name="aibase",
                title="AIbase",
                description="AI 工具数据库，收录大量 AI 应用和工具。",
                features="工具数据库\n分类搜索\n工具推荐",
                image_url="https://www.google.com/s2/favicons?domain=aibase.com&sz=128",
                official_url="https://aibase.com",
                order_index=6
            ),
            Product(
                name="huggingface",
                title="Hugging Face",
                description="AI 模型和数据集平台，开源 AI 社区。",
                features="模型库\n数据集\n开源社区",
                image_url="https://www.google.com/s2/favicons?domain=huggingface.co&sz=128",
                official_url="https://huggingface.co",
                order_index=7
            ),
            Product(
                name="futurepedia",
                title="Futurepedia",
                description="AI 工具目录，发现最新的 AI 应用和工具。",
                features="工具目录\n最新资讯\n分类浏览",
                image_url="https://www.google.com/s2/favicons?domain=futurepedia.io&sz=128",
                official_url="https://www.futurepedia.io",
                order_index=8
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

