"""
数据库初始化脚本
创建表结构并插入初始数据
"""
from database import engine, SessionLocal, Base
from models import Product, User, Memo, Article
from auth import get_password_hash
from datetime import datetime


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
                image_url="/icons/moltbot.png",
                official_url="https://moltbot.com",
                order_index=1
            ),
            Product(
                name="notebooklm",
                title="NotebookLM",
                description="Google 的 AI 笔记助手，帮助整理和分析笔记内容。",
                features="智能笔记\n自动摘要\n内容问答",
                image_url="/icons/notebooklm.png",
                official_url="https://notebooklm.google.com",
                order_index=2
            ),
            Product(
                name="manus",
                title="Manus",
                description="智能文档处理系统，支持多格式文档和信息提取。",
                features="文档处理\n信息提取\n知识库",
                image_url="/icons/manus.png",
                official_url="https://manus.ai",
                order_index=3
            ),
            Product(
                name="cursor",
                title="Cursor",
                description="AI 驱动的代码编辑器，提升编程效率。",
                features="AI 编程\n代码补全\n智能提示",
                image_url="/icons/cursor.png",
                official_url="https://cursor.sh",
                order_index=4
            ),
            Product(
                name="toolify",
                title="Toolify.ai",
                description="AI 工具聚合平台，发现和比较各种 AI 工具。",
                features="工具聚合\nAI 搜索\n工具比较",
                image_url="/icons/toolify.png",
                official_url="https://toolify.ai",
                order_index=5
            ),
            Product(
                name="aibase",
                title="AIbase",
                description="AI 工具数据库，收录大量 AI 应用和工具。",
                features="工具数据库\n分类搜索\n工具推荐",
                image_url="/icons/aibase.png",
                official_url="https://aibase.com",
                order_index=6
            ),
            Product(
                name="huggingface",
                title="Hugging Face",
                description="AI 模型和数据集平台，开源 AI 社区。",
                features="模型库\n数据集\n开源社区",
                image_url="/icons/huggingface.png",
                official_url="https://huggingface.co",
                order_index=7
            ),
            Product(
                name="futurepedia",
                title="Futurepedia",
                description="AI 工具目录，发现最新的 AI 应用和工具。",
                features="工具目录\n最新资讯\n分类浏览",
                image_url="/icons/futurepedia.png",
                official_url="https://www.futurepedia.io",
                order_index=8
            ),
        ]
        
        for product in products:
            db.add(product)
        
        db.commit()
        print(f"成功初始化 {len(products)} 个产品数据")
        
        # 检查管理员账号
        admin = db.query(User).filter(User.username == "Admin").first()
        if admin:
            print("管理员账号已存在")
        else:
            print("管理员账号未创建，请通过 /admin/setup 页面设置管理员密码")
        
        # 初始化文章数据
        if db.query(Article).count() == 0:
            article = Article(
                title="蒸汽、钢铁与无限心智（Steam, Steel, and Infinite Minds）",
                publish_date=datetime(2025, 12, 23),
                author="Ivan Zhao（赵一帆，Notion 联合创始人兼 CEO）",
                original_url="https://www.notion.com/blog/steam-steel-and-infinite-minds-ai",
                category="科技",
                excerpt="Notion创始人Ivan Zhao关于AI如何改变知识工作的深度思考，探讨了从个人到组织再到整个经济层面的变革。",
                content="""
                <h3>蒸汽、钢铁与无限心智</h3>
                <p>每个时代都由其奇迹材料塑造。钢铁锻造了镀金时代。半导体开启了数字时代。现在，AI作为无限心智已经到来。如果历史教会我们什么，那就是掌握这些材料的人定义了时代。</p>
                
                <h4>个人：从自行车到汽车</h4>
                <p>第一个迹象可以在知识工作的高级从业者中找到：程序员。</p>
                <p>我的联合创始人Simon曾经是我们所说的10倍程序员，但他现在很少写代码了。走过他的办公桌，你会看到他同时协调三四个AI编程代理，它们不仅打字更快，还会思考，这使他成为了30-40倍的工程师。他可以在午餐前或睡前排队任务，让它们在他离开时工作。他成为了无限心智的管理者。</p>
                
                <h4>组织：钢铁与蒸汽</h4>
                <p>公司是最近的发明。它们随着规模扩大而退化并达到极限。</p>
                <p>几百年前，大多数公司都是十几个人的作坊。现在我们有了拥有数十万人的跨国公司。通信基础设施（通过会议和消息连接的人脑）在指数级负载下崩溃。我们试图用层级、流程和文档来解决这个问题。但我们一直在用人类规模的工具解决工业规模的问题，就像用木头建造摩天大楼一样。</p>
                
                <p><strong>AI是组织的钢铁。</strong>它有潜力在工作流程中保持上下文，并在需要时浮现决策，而不会有噪音。人类通信不再需要成为承重墙。每周两小时的对齐会议变成了五分钟的异步审查。需要三级批准的执行决策可能很快在几分钟内发生。公司可以真正扩展，而不会出现我们认为是不可避免的退化。</p>
                
                <h4>经济：从佛罗伦萨到特大城市</h4>
                <p>钢铁和蒸汽不仅改变了建筑和工厂。它们改变了城市。</p>
                <p>直到几百年前，城市都是人类规模的。你可以在四十分钟内步行穿过佛罗伦萨。生活的节奏是由一个人能走多远、声音能传多远来设定的。</p>
                <p>然后钢架使摩天大楼成为可能。蒸汽机驱动的铁路将城市中心连接到腹地。电梯、地铁、高速公路随之而来。城市在规模和密度上爆炸式增长。东京。重庆。达拉斯。</p>
                
                <p>这些不仅仅是佛罗伦萨的更大版本。它们是不同的生活方式。特大城市令人迷失方向、匿名、难以导航。这种不可读性是规模的代价。但它们也提供了更多机会、更多自由。比人类规模的文艺复兴城市能够支持的更多的人以更多的组合做更多的事情。</p>
                
                <p>我认为知识经济即将经历同样的转变。</p>
                """
            )
            db.add(article)
            db.commit()
            print("文章数据初始化成功！")
        else:
            print("文章数据已存在，跳过初始化")
        
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

