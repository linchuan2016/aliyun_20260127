"""
Pydantic 模型定义（用于请求和响应验证）
"""
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
    excerpt: str = None


class ArticleUpdate(BaseModel):
    """更新文章请求模型"""
    title: str = None
    publish_date: str = None
    author: str = None
    original_url: str = None
    category: str = None
    content: str = None
    excerpt: str = None


class ArticleResponse(BaseModel):
    """文章响应模型"""
    id: int
    title: str
    publish_date: str
    author: str
    original_url: str | None = None
    category: str | None = None
    content: str | None = None
    excerpt: str | None = None
    created_at: str | None = None
    updated_at: str | None = None

