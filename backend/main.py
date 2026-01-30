import os
from datetime import timedelta
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

# 导入数据库相关（必须在 models 之前）
from database import get_db, engine, Base
from models import Product, User, Memo, Article
from schemas import (
    UserRegister, UserLogin, Token, UserResponse,
    MemoCreate, MemoUpdate, MemoResponse,
    ArticleCreate, ArticleUpdate, ArticleResponse
)
from auth import (
    get_password_hash,
    verify_password,
    create_access_token,
    get_current_active_user,
    ACCESS_TOKEN_EXPIRE_MINUTES
)

app = FastAPI(title="My Fullstack App API")

# 确保数据库表已创建
try:
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully")
except Exception as e:
    print(f"Warning: Database initialization error: {e}")

# CORS 配置：允许前端域名访问
# 本地开发：默认允许本地前端端口
# 生产环境：从环境变量读取允许的域名
allowed_origins_env = os.getenv("ALLOWED_ORIGINS", "")
if allowed_origins_env:
    # 生产环境：使用环境变量配置的域名
    allow_origins = [origin.strip() for origin in allowed_origins_env.split(",")]
else:
    # 本地开发：允许常见的本地前端地址
    # 生产环境：如果通过Nginx代理，允许所有来源（因为Nginx会处理CORS）
    allow_origins = [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://47.112.29.212",
        "https://linchuan.tech",
        "http://linchuan.tech",
    ]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allow_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/data")
async def get_data():
    return {"message": "Hello World！"}

@app.get("/api/health")
async def health_check():
    """健康检查接口"""
    return {"status": "ok"}

@app.get("/api/products")
async def get_products(db: Session = Depends(get_db)):
    """获取所有产品列表"""
    products = db.query(Product).order_by(Product.order_index).all()
    return {"products": [product.to_dict() for product in products]}

@app.get("/api/products/{product_name}")
async def get_product(product_name: str, db: Session = Depends(get_db)):
    """根据产品名称获取单个产品信息"""
    product = db.query(Product).filter(Product.name == product_name).first()
    if not product:
        return {"error": "Product not found"}, 404
    return {"product": product.to_dict()}


# ==================== 认证相关路由 ====================

@app.post("/api/auth/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserRegister, db: Session = Depends(get_db)):
    """用户注册"""
    # 不再验证密码长度，只验证密码是否正确
    
    # 检查用户名是否已存在
    if db.query(User).filter(User.username == user_data.username).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="用户名已被注册"
        )
    
    # 检查邮箱是否已存在
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="邮箱已被注册"
        )
    
    # 创建新用户
    hashed_password = get_password_hash(user_data.password)
    new_user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    return new_user.to_dict()


@app.post("/api/auth/login", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """用户登录（使用 OAuth2PasswordRequestForm 兼容标准格式）"""
    # 不再验证密码长度，只验证密码是否正确
    
    user = db.query(User).filter(User.username == form_data.username).first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="用户名或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="账号已被禁用"
        )
    
    # 创建访问令牌
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user.to_dict()
    }


@app.post("/api/auth/login-json", response_model=Token)
async def login_json(user_data: UserLogin, db: Session = Depends(get_db)):
    """用户登录（JSON 格式）"""
    try:
        # 不再验证密码长度，只验证密码是否正确
        user = db.query(User).filter(User.username == user_data.username).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户名或密码错误",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        if not verify_password(user_data.password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="用户名或密码错误",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="账号已被禁用"
            )
        
        # 创建访问令牌
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.username}, expires_delta=access_token_expires
        )
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user": user.to_dict()
        }
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        print(f"Login error: {str(e)}")
        print(traceback.format_exc())
        error_msg = str(e)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"服务器错误：{error_msg}"
        )


@app.get("/api/auth/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_active_user)):
    """获取当前登录用户信息"""
    return current_user.to_dict()


# ==================== 后台管理相关路由 ====================

@app.get("/api/admin/users")
async def get_all_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取所有用户列表（需要登录）"""
    users = db.query(User).offset(skip).limit(limit).all()
    total = db.query(User).count()
    return {
        "users": [user.to_dict() for user in users],
        "total": total
    }


@app.get("/api/admin/users/{user_id}")
async def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取单个用户信息"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user.to_dict()


@app.delete("/api/admin/users/{user_id}")
async def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除用户"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # 不能删除自己
    if user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")
    
    db.delete(user)
    db.commit()
    return {"message": "User deleted successfully"}


@app.patch("/api/admin/users/{user_id}/status")
async def update_user_status(
    user_id: int,
    is_active: bool,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新用户状态（激活/禁用）"""
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # 不能禁用自己
    if user.id == current_user.id and not is_active:
        raise HTTPException(status_code=400, detail="Cannot deactivate yourself")
    
    user.is_active = is_active
    db.commit()
    db.refresh(user)
    return user.to_dict()


@app.get("/api/admin/check")
async def check_admin_exists(db: Session = Depends(get_db)):
    """检查管理员账号是否存在"""
    admin = db.query(User).filter(User.username == "Admin").first()
    return {"exists": admin is not None}


@app.post("/api/admin/setup")
async def setup_admin_user(
    password_data: dict,
    db: Session = Depends(get_db)
):
    """设置管理员账号密码（仅当没有管理员时可用）"""
    # 检查是否已有管理员
    admin = db.query(User).filter(User.username == "Admin").first()
    if admin:
        raise HTTPException(status_code=400, detail="管理员账号已存在，无法重新设置")
    
    password = password_data.get("password")
    if not password:
        raise HTTPException(status_code=400, detail="密码不能为空")
    
    try:
        admin_user = User(
            username="Admin",
            email="admin@example.com",
            hashed_password=get_password_hash(password),
            is_active=True
        )
        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)
        return {
            "message": "管理员账号创建成功",
            "username": "Admin"
        }
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"创建管理员账号失败: {str(e)}")


# ==================== 备忘录相关路由 ====================

@app.get("/api/memos", response_model=list[MemoResponse])
async def get_memos(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取当前用户的所有备忘录"""
    memos = db.query(Memo).filter(Memo.user_id == current_user.id).order_by(
        Memo.is_pinned.desc(), Memo.updated_at.desc()
    ).all()
    return [memo.to_dict() for memo in memos]


@app.post("/api/memos", response_model=MemoResponse, status_code=status.HTTP_201_CREATED)
async def create_memo(
    memo_data: MemoCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建新备忘录"""
    memo = Memo(
        user_id=current_user.id,
        title=memo_data.title,
        content=memo_data.content,
        is_pinned=memo_data.is_pinned
    )
    db.add(memo)
    db.commit()
    db.refresh(memo)
    return memo.to_dict()


@app.get("/api/memos/{memo_id}", response_model=MemoResponse)
async def get_memo(
    memo_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """获取单个备忘录"""
    memo = db.query(Memo).filter(
        Memo.id == memo_id,
        Memo.user_id == current_user.id
    ).first()
    if not memo:
        raise HTTPException(status_code=404, detail="Memo not found")
    return memo.to_dict()


@app.patch("/api/memos/{memo_id}", response_model=MemoResponse)
async def update_memo(
    memo_id: int,
    memo_data: MemoUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新备忘录"""
    memo = db.query(Memo).filter(
        Memo.id == memo_id,
        Memo.user_id == current_user.id
    ).first()
    if not memo:
        raise HTTPException(status_code=404, detail="Memo not found")
    
    if memo_data.title is not None:
        memo.title = memo_data.title
    if memo_data.content is not None:
        memo.content = memo_data.content
    if memo_data.is_pinned is not None:
        memo.is_pinned = memo_data.is_pinned
    
    db.commit()
    db.refresh(memo)
    return memo.to_dict()


@app.delete("/api/memos/{memo_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_memo(
    memo_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除备忘录"""
    memo = db.query(Memo).filter(
        Memo.id == memo_id,
        Memo.user_id == current_user.id
    ).first()
    if not memo:
        raise HTTPException(status_code=404, detail="Memo not found")
    
    db.delete(memo)
    db.commit()
    return None


# ==================== 文章相关路由 ====================

@app.get("/api/articles", response_model=list[ArticleResponse])
async def get_articles(
    skip: int = 0,
    limit: int = 100,
    order_by: str = "publish_date",
    order: str = "desc",
    db: Session = Depends(get_db)
):
    """获取文章列表（支持排序）"""
    # 验证排序字段
    valid_order_fields = ["title", "publish_date", "author", "category", "created_at"]
    if order_by not in valid_order_fields:
        order_by = "publish_date"
    
    # 验证排序方向
    if order.lower() not in ["asc", "desc"]:
        order = "desc"
    
    # 构建查询
    query = db.query(Article)
    
    # 排序
    order_column = getattr(Article, order_by)
    if order.lower() == "desc":
        query = query.order_by(order_column.desc())
    else:
        query = query.order_by(order_column.asc())
    
    articles = query.offset(skip).limit(limit).all()
    return [article.to_dict() for article in articles]


@app.get("/api/articles/{article_id}", response_model=ArticleResponse)
async def get_article(
    article_id: int,
    db: Session = Depends(get_db)
):
    """获取单个文章"""
    article = db.query(Article).filter(Article.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    return article.to_dict()


@app.post("/api/admin/articles", response_model=ArticleResponse, status_code=status.HTTP_201_CREATED)
async def create_article(
    article_data: ArticleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """创建文章（需要管理员权限）"""
    from datetime import datetime
    
    # 解析发布时间
    try:
        publish_date = datetime.fromisoformat(article_data.publish_date.replace('Z', '+00:00'))
    except:
        publish_date = datetime.now()
    
    article = Article(
        title=article_data.title,
        publish_date=publish_date,
        author=article_data.author,
        original_url=article_data.original_url,
        category=article_data.category,
        content=article_data.content,
        excerpt=article_data.excerpt
    )
    db.add(article)
    db.commit()
    db.refresh(article)
    return article.to_dict()


@app.patch("/api/admin/articles/{article_id}", response_model=ArticleResponse)
async def update_article(
    article_id: int,
    article_data: ArticleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """更新文章（需要管理员权限）"""
    article = db.query(Article).filter(Article.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    
    if article_data.title is not None:
        article.title = article_data.title
    if article_data.publish_date is not None:
        from datetime import datetime
        try:
            article.publish_date = datetime.fromisoformat(article_data.publish_date.replace('Z', '+00:00'))
        except:
            pass
    if article_data.author is not None:
        article.author = article_data.author
    if article_data.original_url is not None:
        article.original_url = article_data.original_url
    if article_data.category is not None:
        article.category = article_data.category
    if article_data.content is not None:
        article.content = article_data.content
    if article_data.excerpt is not None:
        article.excerpt = article_data.excerpt
    
    db.commit()
    db.refresh(article)
    return article.to_dict()


@app.delete("/api/admin/articles/{article_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_article(
    article_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """删除文章（需要管理员权限）"""
    article = db.query(Article).filter(Article.id == article_id).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    
    db.delete(article)
    db.commit()
    return None

if __name__ == "__main__":
    import uvicorn
    # 本地开发时使用
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host=host, port=port)

