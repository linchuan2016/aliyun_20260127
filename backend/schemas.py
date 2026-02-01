"""
Pydantic 模型定义（用于请求和响应验证）
"""
from typing import Optional, List
from pydantic import BaseModel, EmailStr


class UserRegister(BaseModel):
    """用户注册请求模型"""
    username: str
    email: EmailStr
    password: str


class UserLogin(BaseModel):
    """用户登录请求模型"""
    username: str
    password: str


class Token(BaseModel):
    """Token 响应模型"""
    access_token: str
    token_type: str
    user: dict


class UserResponse(BaseModel):
    """用户信息响应模型"""
    id: int
    username: str
    email: str
    is_active: bool


class MemoCreate(BaseModel):
    """创建备忘录请求模型"""
    title: str
    content: str = ""
    is_pinned: bool = False


class MemoUpdate(BaseModel):
    """更新备忘录请求模型"""
    title: str = None
    content: str = None
    is_pinned: bool = None


class MemoResponse(BaseModel):
    """备忘录响应模型"""
    id: int
    user_id: int
    title: str
    content: str
    is_pinned: bool
    created_at: str = None
    updated_at: str = None


class ArticleCreate(BaseModel):
    """创建文章请求模型"""
    title: str
    publish_date: str
    author: str
    original_url: str = None
    category: str = None
    content: str = None
    content_en: Optional[str] = None
    cover_image: Optional[str] = None
    excerpt: str = None


class ArticleUpdate(BaseModel):
    """更新文章请求模型"""
    title: str = None
    publish_date: str = None
    author: str = None
    original_url: str = None
    category: str = None
    content: str = None
    content_en: Optional[str] = None
    cover_image: Optional[str] = None
    excerpt: str = None


class ArticleResponse(BaseModel):
    """文章响应模型"""
    id: int
    title: str
    publish_date: str
    author: str
    original_url: Optional[str] = None
    category: Optional[str] = None
    content: Optional[str] = None
    content_en: Optional[str] = None
    cover_image: Optional[str] = None
    excerpt: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class BookCreate(BaseModel):
    """创建书籍请求模型"""
    title: str
    cover_image: str = None
    author: str
    publish_date: str
    description: Optional[str] = None


class BookUpdate(BaseModel):
    """更新书籍请求模型"""
    title: str = None
    cover_image: str = None
    author: str = None
    publish_date: str = None
    description: Optional[str] = None


class BookResponse(BaseModel):
    """书籍响应模型"""
    id: int
    title: str
    cover_image: Optional[str] = None
    author: str
    publish_date: str
    description: Optional[str] = None
    created_at: Optional[str] = None
    updated_at: Optional[str] = None


class ProductCreate(BaseModel):
    """创建产品请求模型"""
    name: str
    title: str
    description: str
    features: Optional[str] = None
    image_url: Optional[str] = None
    official_url: Optional[str] = None
    order_index: int = 0


class ProductUpdate(BaseModel):
    """更新产品请求模型"""
    name: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    features: Optional[str] = None
    image_url: Optional[str] = None
    official_url: Optional[str] = None
    order_index: Optional[int] = None


class ProductResponse(BaseModel):
    """产品响应模型"""
    id: int
    name: str
    title: str
    description: str
    features: Optional[List[str]] = None
    image_url: Optional[str] = None
    official_url: Optional[str] = None
    order_index: int
    created_at: Optional[str] = None
    updated_at: Optional[str] = None

