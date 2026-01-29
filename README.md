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
│   ├── init_db.py   # 数据库初始化脚本
│   └── requirements.txt
├── frontend/        # Vue 3 前端
│   ├── src/
│   │   ├── App.vue  # 主组件
│   │   └── components/
│   │       └── ProductCard.vue  # 产品卡片组件
│   ├── package.json
│   └── vite.config.js
├── deploy/          # 部署配置
│   ├── my-fullstack-app.service      # systemd 服务文件（HTTP）
│   ├── my-fullstack-app-ssl.service  # systemd 服务文件（HTTPS）
│   ├── nginx.conf                     # Nginx 配置（HTTP）
│   ├── nginx-ssl.conf                 # Nginx 配置（HTTPS）
│   ├── apply-ssl-complete-fixed.sh    # SSL 配置应用脚本
│   ├── upload-ssl-cert.bat            # SSL 证书上传脚本（Windows）
│   ├── upload-ssl-cert.ps1            # SSL 证书上传脚本（PowerShell）
│   └── sync-to-server.ps1             # 代码同步脚本
├── .vscode/         # 编辑器配置
│   ├── settings.json      # VS Code/Cursor 设置
│   └── extensions.json    # 推荐插件列表
├── start-local.ps1  # 本地启动脚本（Windows）
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

- `GET /api/products` - 获取所有产品列表
- `GET /api/products/{product_name}` - 获取单个产品信息
- `GET /api/health` - 健康检查
- `GET /api/data` - 测试接口

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

#### 1. 基础部署（HTTP）

1. 将代码同步到服务器
2. 配置 Nginx：`deploy/nginx.conf`
3. 配置 systemd：`deploy/my-fullstack-app.service`
4. 启动服务

#### 2. SSL 部署（HTTPS）

1. **上传 SSL 证书**
   ```powershell
   # Windows 本地执行
   .\deploy\upload-ssl-cert.bat
   ```

2. **应用 SSL 配置**
   ```bash
   # 在服务器上执行
   chmod +x deploy/apply-ssl-complete-fixed.sh
   sudo ./deploy/apply-ssl-complete-fixed.sh
   ```

3. **重启服务**
   ```bash
   sudo systemctl restart my-fullstack-app
   sudo systemctl restart nginx
   ```

详细部署步骤请参考 `deploy/` 目录下的配置文件。

## 许可证

MIT
