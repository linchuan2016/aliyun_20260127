# 更新服务器图标路径指南

## 问题说明
如果服务器上的图标仍然依赖外部服务（如Google favicon），需要更新数据库中的图标路径为本地路径。

## 快速部署步骤

### 方法一：使用部署脚本（推荐）

1. **将更新后的代码同步到服务器**
   ```bash
   # 在本地执行
   git add .
   git commit -m "修复图标依赖外部服务问题"
   git push gitee main
   ```

2. **在服务器上拉取最新代码**
   ```bash
   # SSH登录服务器后执行
   cd /var/www/my-fullstack-app
   git pull gitee main
   ```

3. **确保图标文件已存在**
   ```bash
   # 检查图标文件
   ls -la /var/www/my-fullstack-app/frontend/dist/icons/
   
   # 如果图标文件不存在，需要先构建前端
   cd /var/www/my-fullstack-app/frontend
   npm run build
   ```

4. **运行更新脚本**
   ```bash
   cd /var/www/my-fullstack-app
   chmod +x deploy/update-icons-on-server.sh
   ./deploy/update-icons-on-server.sh
   ```

### 方法二：手动执行命令

1. **更新数据库中的图标路径**
   ```bash
   cd /var/www/my-fullstack-app/backend
   source venv/bin/activate  # 如果使用虚拟环境
   python update_icons.py
   ```

2. **重启后端服务**
   ```bash
   sudo systemctl restart my-fullstack-app
   ```

3. **如果前端代码有更新，重新构建**
   ```bash
   cd /var/www/my-fullstack-app/frontend
   npm run build
   sudo systemctl reload nginx
   ```

## 验证更新

1. **检查数据库中的图标路径**
   ```bash
   cd /var/www/my-fullstack-app/backend
   source venv/bin/activate
   python -c "from database import SessionLocal; from models import Product; db = SessionLocal(); products = db.query(Product).all(); [print(f'{p.name}: {p.image_url}') for p in products]"
   ```
   应该看到所有 `image_url` 都是 `/icons/xxx.png` 格式，而不是 `http://` 开头的URL。

2. **检查网站**
   - 访问网站首页
   - 打开浏览器开发者工具（F12）
   - 查看 Network 标签，确认图标请求都是本地路径（如 `/icons/moltbot.png`）
   - 不应该看到对 `google.com` 或 `faviconkit.com` 的请求

## 注意事项

- 确保 `frontend/dist/icons/` 目录下存在所有图标文件
- 如果图标文件缺失，前端会自动使用占位图标 `/icons/placeholder.svg`
- 前端代码已强制使用本地路径，即使数据库中有外部URL也会自动转换

