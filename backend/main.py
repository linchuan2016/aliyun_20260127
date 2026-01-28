import os
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

# 导入数据库相关（必须在 models 之前）
from database import get_db, engine, Base
from models import Product

app = FastAPI(title="My Fullstack App API")

# 确保数据库表已创建
Base.metadata.create_all(bind=engine)

# CORS 配置：允许前端域名访问
# 本地开发：默认允许本地前端端口
# 生产环境：从环境变量读取允许的域名
allowed_origins_env = os.getenv("ALLOWED_ORIGINS", "")
if allowed_origins_env:
    # 生产环境：使用环境变量配置的域名
    allow_origins = [origin.strip() for origin in allowed_origins_env.split(",")]
else:
    # 本地开发：允许常见的本地前端地址
    allow_origins = [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
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

if __name__ == "__main__":
    import uvicorn
    # 本地开发时使用
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host=host, port=port)

