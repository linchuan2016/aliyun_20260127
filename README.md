# My Fullstack App

全栈 Web 应用，使用 FastAPI + Vue 3 + SQLite/MySQL 构建。

## 功能特性

- 🎨 现代化的产品展示主页
- 🗄️ 数据库驱动的产品信息管理
- 📱 响应式设计，支持移动端
- 🚀 快速部署到阿里云服务器

## 项目结构

```
my-fullstack-app/
├── backend/          # Python FastAPI 后端
│   ├── main.py      # 主应用文件
│   ├── database.py  # 数据库配置
│   ├── models.py    # 数据模型
│   ├── schemas.py   # Pydantic 模型
│   ├── auth.py      # 认证相关
│   ├── init_db.py   # 数据库初始化脚本
│   ├── export_articles.py  # 导出文章脚本
│   ├── import_articles.py # 导入文章脚本
│   ├── download_book_covers.py      # 下载书籍封面
│   ├── download_article_covers.py   # 下载文章封面
│   ├── scrape_notion_article.py     # 爬取Notion文章
│   └── requirements.txt
├── frontend/        # Vue 3 前端
│   ├── src/
│   │   ├── App.vue  # 主组件
│   │   ├── views/   # 页面组件
│   │   ├── components/  # 通用组件
│   │   ├── router/  # 路由配置
│   │   └── composables/ # 组合式函数
│   ├── public/      # 静态资源
│   │   ├── book-covers/    # 书籍封面
│   │   ├── article-covers/ # 文章封面
│   │   └── icons/   # 图标
│   ├── package.json
│   └── vite.config.js
├── data/            # 数据文件
│   └── articles.json # 文章数据（用于Git同步）
├── scripts/         # 脚本文件夹
│   ├── local/       # 本地开发脚本
│   └── deploy/      # 部署配置和脚本
│       ├── my-fullstack-app.service      # systemd 服务文件
│       ├── nginx.conf                     # Nginx 配置
│       ├── sync-on-server-complete.sh     # 服务器同步脚本
│       └── sync-quick.ps1                 # 快速同步脚本（Windows）
├── start-local.ps1  # 本地启动脚本（Windows）
├── start-local.bat  # 本地启动脚本（批处理）
└── README.md
```

## 快速开始

### 本地开发

#### 1. 后端设置

```bash
cd backend

# 创建虚拟环境
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 安装依赖
pip install -r requirements.txt

# 初始化数据库（SQLite）
python init_db.py

# 启动后端
python main.py
```

后端运行在 `http://127.0.0.1:8000`

#### 2. 前端设置

```bash
cd frontend

# 安装依赖
npm install

# 启动开发服务器
npm run dev
```

前端运行在 `http://localhost:5173`

#### 3. 使用启动脚本（Windows）

```powershell
.\start-local.ps1
```

#### 4. 初始化管理员账号

首次启动后，访问 `http://localhost:5173/admin` 会自动跳转到管理员设置页面。

**安全说明：**
- 管理员密码不会硬编码在代码中
- 首次访问时通过 web 界面设置管理员密码
- 所有辅助脚本（如 `create_admin.py`）已配置为不提交到 git

## 数据库

### 本地开发（SQLite）

默认使用 SQLite，数据库文件：`backend/products.db`（已添加到 .gitignore）

初始化：
```bash
cd backend
python init_db.py
```

### 生产环境（MySQL）

1. 安装 MySQL
2. 创建数据库
3. 配置环境变量 `DATABASE_URL=mysql+pymysql://user:password@host:port/database`
4. 运行初始化脚本

## API 接口

### 公开接口
- `GET /api/products` - 获取所有产品列表
- `GET /api/products/{product_name}` - 获取单个产品信息
- `GET /api/articles` - 获取文章列表
- `GET /api/health` - 健康检查

### 认证接口
- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login` - 用户登录
- `POST /api/auth/login-json` - 用户登录（JSON格式）
- `GET /api/auth/me` - 获取当前用户信息

### 管理员接口
- `GET /api/admin/check` - 检查管理员是否存在
- `POST /api/admin/setup` - 设置管理员密码（仅首次可用）
- `GET /api/admin/users` - 获取用户列表（需登录）
- `GET /api/admin/articles` - 获取文章列表（需登录）

API 文档：http://127.0.0.1:8000/docs

## 技术栈

- **后端**: FastAPI, SQLAlchemy, SQLite/MySQL, Uvicorn
- **前端**: Vue 3, Vite
- **部署**: Nginx, systemd, MySQL

## 产品数据

当前包含三个产品的介绍：
- **Moltbot** - 智能对话机器人
- **NotebookLM** - 智能笔记助手
- **Manus** - 智能文档处理

## 文章数据同步

Blog 文章数据可以导出到 JSON 文件并同步到 Git 仓库，实现跨环境的数据持久化和同步。

### 导出文章到 Git

1. **使用便捷脚本（推荐）**
   ```powershell
   # Windows 本地执行
   .\export-and-sync-articles.ps1
   ```
   这个脚本会：
   - 自动导出所有文章到 `data/articles.json`
   - 检查 Git 状态
   - 提交更改并可选推送到 Gitee

2. **手动导出**
   ```powershell
   cd backend
   ..\venv\Scripts\python.exe export_articles.py
   ```
   导出的文件位于 `data/articles.json`

3. **提交到 Git**
   ```bash
   git add data/articles.json
   git commit -m "更新文章数据"
   git push gitee main
   ```

### 在服务器上导入文章

服务器上的同步脚本（`scripts/deploy/阿里云服务器直接同步命令.sh` 和 `scripts/deploy/sync-on-server-complete.sh`）会自动检测并导入 `data/articles.json` 文件。

如果文章已存在（根据标题和发布时间判断），默认会更新现有文章。可以通过修改 `backend/import_articles.py` 中的 `update_existing` 参数来控制行为。

### 手动导入文章

```bash
# 在服务器上执行
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python import_articles.py
```

## 编辑器设置

### Vue 文件语法高亮

如果 Vue 文件没有语法高亮，请安装以下插件：

1. **Volar** (Vue Language Features) - Vue 3 官方推荐
2. **TypeScript Vue Plugin** (Volar) - TypeScript 支持

安装方法：
- 按 `Ctrl+Shift+X` 打开扩展面板
- 搜索 "Volar" 并安装
- 重启编辑器

项目已包含 `.vscode/settings.json` 和 `.vscode/extensions.json` 配置文件。

## 部署

### 阿里云服务器部署

#### 快速同步代码（在服务器上执行）

```bash
cd /var/www/my-fullstack-app && \
git stash push -m backup 2>/dev/null || true && \
git fetch gitee main && \
git reset --hard gitee/main
```

#### 完整部署流程

1. **同步代码并创建服务文件**
   ```bash
   # 在服务器上执行完整修复命令（包含服务文件创建）
   # 参考 scripts/deploy/完整修复Blog和Book.sh
   ```

2. **配置 Nginx**
   ```bash
   sudo cp scripts/deploy/nginx.conf /etc/nginx/sites-available/my-fullstack-app
   sudo ln -s /etc/nginx/sites-available/my-fullstack-app /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

3. **启动服务**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable my-fullstack-app
   sudo systemctl start my-fullstack-app
   ```

#### SSL 部署（HTTPS）

1. **上传 SSL 证书**
   ```powershell
   # Windows 本地执行
   .\deploy\upload-ssl-cert.bat
   ```

2. **应用 SSL 配置**
   ```bash
   # 在服务器上执行
   chmod +x scripts/deploy/apply-ssl-complete-fixed.sh
   sudo ./scripts/deploy/apply-ssl-complete-fixed.sh
   ```

3. **重启服务**
   ```bash
   sudo systemctl restart my-fullstack-app
   sudo systemctl restart nginx
   ```

详细部署步骤请参考 `scripts/deploy/README.md`。

## 许可证

MIT
