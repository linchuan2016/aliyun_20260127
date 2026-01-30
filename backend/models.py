"""
数据库模型定义
"""
from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base


class User(Base):
    """用户模型"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False, comment="用户名")
    email = Column(String(100), unique=True, index=True, nullable=False, comment="邮箱")
    hashed_password = Column(String(255), nullable=False, comment="加密后的密码")
    is_active = Column(Boolean, default=True, comment="是否激活")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 关联备忘录
    memos = relationship("Memo", back_populates="user", cascade="all, delete-orphan")

    def to_dict(self):
        """转换为字典（不包含密码）"""
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Product(Base):
    """产品介绍模型"""
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False, comment="产品名称")
    title = Column(String(200), nullable=False, comment="产品标题")
    description = Column(Text, nullable=False, comment="产品描述")
    features = Column(Text, comment="产品特性（JSON 格式或换行分隔）")
    image_url = Column(String(500), comment="产品图片 URL")
    official_url = Column(String(500), comment="官方网站 URL")
    order_index = Column(Integer, default=0, comment="显示顺序")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    def to_dict(self):
        """转换为字典"""
        return {
            "id": self.id,
            "name": self.name,
            "title": self.title,
            "description": self.description,
            "features": self.features.split("\n") if self.features else [],
            "image_url": self.image_url,
            "official_url": self.official_url,
            "order_index": self.order_index,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Memo(Base):
    """备忘录模型"""
    __tablename__ = "memos"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True, comment="用户ID")
    title = Column(String(200), nullable=False, comment="备忘录标题")
    content = Column(Text, comment="备忘录内容")
    is_pinned = Column(Boolean, default=False, comment="是否置顶")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # 关联用户
    user = relationship("User", back_populates="memos")

    def to_dict(self):
        """转换为字典"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "title": self.title,
            "content": self.content,
            "is_pinned": self.is_pinned,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


class Article(Base):
    """文章模型"""
    __tablename__ = "articles"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(500), nullable=False, comment="文章标题")
    publish_date = Column(DateTime(timezone=True), nullable=False, comment="发布时间")
    author = Column(String(200), nullable=False, comment="作者")
    original_url = Column(String(1000), comment="原文地址")
    category = Column(String(100), comment="分类")
    content = Column(Text, comment="文章内容")
    excerpt = Column(Text, comment="文章摘要")
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    def to_dict(self):
        """转换为字典"""
        return {
            "id": self.id,
            "title": self.title,
            "publish_date": self.publish_date.isoformat() if self.publish_date else None,
            "author": self.author,
            "original_url": self.original_url,
            "category": self.category,
            "content": self.content,
            "excerpt": self.excerpt,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
