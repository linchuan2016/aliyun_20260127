# 本地开发指南

## 快速开始

### 1. 启动后端服务

打开第一个终端窗口：

```bash
# 进入后端目录
cd backend

# 激活虚拟环境（如果使用虚拟环境）
# Windows:
..\venv\Scripts\activate
# Linux/Mac:
# source ../venv/bin/activate

# 安装依赖（如果还没安装）
pip install -r requirements.txt

# 启动后端服务
python main.py
```

后端服务将在 `http://127.0.0.1:8000` 启动

### 2. 启动前端服务

打开第二个终端窗口：

```bash
# 进入前端目录
cd frontend

# 安装依赖（如果还没安装）
npm install

# 启动前端开发服务器
npm run dev
```

前端服务将在 `http://localhost:5173` 启动（Vite 默认端口）

### 3. 访问应用

在浏览器中打开：`http://localhost:5173`

你应该能看到：
- 标题："Lin"
- 消息："Hello World！"（从 FastAPI 后端返回）

## 验证后端 API

在浏览器中访问以下地址测试后端：

- API 数据接口：http://127.0.0.1:8000/api/data
- 健康检查接口：http://127.0.0.1:8000/api/health
- API 文档：http://127.0.0.1:8000/docs（FastAPI 自动生成）

## 常见问题

### 问题1：前端显示"无法连接到后端！"

**解决方案：**
1. 确认后端服务正在运行（检查终端是否有错误）
2. 确认后端运行在 `http://127.0.0.1:8000`
3. 检查浏览器控制台（F12）查看具体错误信息
4. 确认 CORS 配置正确（后端已配置允许本地前端端口）

### 问题2：CORS 跨域错误

后端已自动配置允许以下本地地址：
- `http://localhost:5173`（Vite 默认）
- `http://127.0.0.1:5173`
- `http://localhost:3000`
- `http://127.0.0.1:3000`

如果使用其他端口，可以：
1. 设置环境变量：`set ALLOWED_ORIGINS=http://localhost:你的端口`（Windows）
2. 或修改 `backend/main.py` 中的 `allow_origins` 列表

### 问题3：端口被占用

**后端端口被占用：**
```bash
# 修改 backend/main.py 中的端口
# 或设置环境变量
set PORT=8001  # Windows
export PORT=8001  # Linux/Mac
python main.py
```

**前端端口被占用：**
Vite 会自动尝试下一个可用端口，或手动指定：
```bash
npm run dev -- --port 5174
```

## 开发提示

1. **热重载**：前端使用 Vite，修改代码后自动刷新
2. **API 测试**：使用 http://127.0.0.1:8000/docs 测试 API
3. **查看日志**：后端日志在终端显示，前端日志在浏览器控制台（F12）

## 修改 API 地址

如果需要修改前端连接的 API 地址：

**方式1：使用环境变量（推荐）**
创建 `frontend/.env.local` 文件：
```
VITE_API_URL=http://127.0.0.1:8000
```

**方式2：修改代码**
编辑 `frontend/src/App.vue`，修改第10行的默认值

