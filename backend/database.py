"""
数据库配置和连接
支持 SQLite（本地开发）和 MySQL（生产环境）
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 数据库配置
# 本地开发使用 SQLite，生产环境使用 MySQL
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite:///./products.db"  # 默认使用 SQLite
)

# 如果是 MySQL，格式应该是：mysql+pymysql://user:password@host:port/database
# 例如：mysql+pymysql://root:password@localhost:3306/myapp

# 创建数据库引擎
if DATABASE_URL.startswith("sqlite"):
    # SQLite 需要特殊配置
    engine = create_engine(
        DATABASE_URL,
        connect_args={"check_same_thread": False}  # SQLite 需要这个参数
    )
else:
    # MySQL 或其他数据库
    engine = create_engine(DATABASE_URL)

# 创建会话工厂
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 创建基础模型类
Base = declarative_base()


# 数据库依赖注入（用于 FastAPI）
def get_db():
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

