"""
更新数据库中的图标路径为本地路径
将所有外部URL（如Google favicon）替换为本地路径
"""
from database import SessionLocal
from models import Product

# 产品名称到图标文件名的映射
ICON_MAP = {
    "moltbot": "moltbot.png",
    "notebooklm": "notebooklm.png",
    "manus": "manus.png",
    "cursor": "cursor.png",
    "toolify": "toolify.png",
    "toolify.ai": "toolify.png",
    "aibase": "aibase.png",
    "huggingface": "huggingface.png",
    "futurepedia": "futurepedia.png",
}

def update_icon_urls():
    """更新所有产品的图标URL为本地路径"""
    db = SessionLocal()
    try:
        products = db.query(Product).all()
        updated_count = 0
        
        for product in products:
            # 如果当前URL是外部URL，更新为本地路径
            if product.image_url and product.image_url.startswith('http'):
                # 根据产品名称获取图标文件名
                product_name = product.name.lower() if product.name else ""
                icon_file = ICON_MAP.get(product_name, "placeholder.svg")
                
                # 更新为本地路径
                old_url = product.image_url
                product.image_url = f"/icons/{icon_file}"
                
                print(f"更新产品 '{product.title}': {old_url} -> {product.image_url}")
                updated_count += 1
        
        if updated_count > 0:
            db.commit()
            print(f"\n成功更新 {updated_count} 个产品的图标路径")
        else:
            print("\n所有产品的图标路径已经是本地路径，无需更新")
            
    except Exception as e:
        db.rollback()
        print(f"更新失败: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("开始更新图标路径...")
    update_icon_urls()
    print("更新完成！")

