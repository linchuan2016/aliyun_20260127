"""
数据库模型定义
"""
from sqlalchemy import Column, Integer, String, Text, DateTime
from sqlalchemy.sql import func
from database import Base


class Product(Base):
    """产品介绍模型"""
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True, nullable=False, comment="产品名称")
    title = Column(String(200), nullable=False, comment="产品标题")
    description = Column(Text, nullable=False, comment="产品描述")
    features = Column(Text, comment="产品特性（JSON 格式或换行分隔）")
    image_url = Column(String(500), comment="产品图片 URL")
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
            "order_index": self.order_index,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }

