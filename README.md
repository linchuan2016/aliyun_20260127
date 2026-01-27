# My Fullstack App

全栈 Web 应用，使用 FastAPI + Vue 3 构建。

## 项目结构

```
my-fullstack-app/
├── backend/          # Python FastAPI 后端
│   ├── main.py      # 主应用文件
│   └── requirements.txt
├── frontend/        # Vue 3 前端
│   ├── src/         # 源代码
│   ├── package.json
│   └── vite.config.js
└── deploy/          # 部署配置
    ├── my-fullstack-app.service  # systemd 服务文件
    └── nginx.conf                # Nginx 配置
```

## 本地开发

### 后端

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

后端运行在 `http://127.0.0.1:8000`

### 前端

```bash
cd frontend
npm install
npm run dev
```

前端运行在 `http://localhost:5173`

## 部署

### 服务器要求

- Python 3.x
- Node.js
- Nginx

### 部署步骤

1. 克隆代码到服务器
2. 创建虚拟环境并安装依赖
3. 构建前端：`cd frontend && npm run build`
4. 配置 systemd 服务（参考 `deploy/my-fullstack-app.service`）
5. 配置 Nginx（参考 `deploy/nginx.conf`）
6. 启动服务

详细部署说明请参考服务器上的部署文档。

## 技术栈

- **后端**: FastAPI, Uvicorn
- **前端**: Vue 3, Vite
- **部署**: Nginx, systemd

