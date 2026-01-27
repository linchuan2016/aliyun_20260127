# 本地启动服务指南

## 快速启动

### 方式一：分两个终端窗口启动

#### 终端1：启动后端

```powershell
# 进入后端目录
cd backend

# 激活虚拟环境
..\venv\Scripts\activate

# 启动后端服务
python main.py
```

后端将在 `http://127.0.0.1:8000` 启动

#### 终端2：启动前端

```powershell
# 进入前端目录
cd frontend

# 启动前端开发服务器
npm run dev
```

前端将在 `http://localhost:5173` 启动

---

### 方式二：使用 PowerShell 后台启动

```powershell
# 启动后端（后台运行）
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; ..\venv\Scripts\activate; python main.py"

# 等待2秒
Start-Sleep -Seconds 2

# 启动前端（后台运行）
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; npm run dev"

Write-Host "后端: http://127.0.0.1:8000" -ForegroundColor Green
Write-Host "前端: http://localhost:5173" -ForegroundColor Green
```

---

## 详细步骤

### 1. 启动后端服务

```powershell
# 进入后端目录
cd D:\Aliyun\my-fullstack-app\backend

# 激活虚拟环境（如果还没激活）
..\venv\Scripts\activate

# 检查依赖是否安装
pip list | Select-String "fastapi|uvicorn"

# 如果没有安装，先安装依赖
pip install -r requirements.txt

# 启动后端
python main.py
```

**成功标志：**
```
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

---

### 2. 启动前端服务

**打开新的 PowerShell 窗口：**

```powershell
# 进入前端目录
cd D:\Aliyun\my-fullstack-app\frontend

# 检查依赖是否安装
Test-Path node_modules

# 如果没有 node_modules，先安装依赖
npm install

# 启动前端开发服务器
npm run dev
```

**成功标志：**
```
  VITE v7.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

---

## 访问应用

1. **前端页面：** http://localhost:5173
2. **后端 API：** http://127.0.0.1:8000/api/data
3. **API 文档：** http://127.0.0.1:8000/docs

---

## 验证服务

### 测试后端 API

```powershell
# 在 PowerShell 中测试
Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/data" | Select-Object -ExpandProperty Content

# 或使用 curl（如果已安装）
curl http://127.0.0.1:8000/api/data
```

### 测试前端

在浏览器中打开：`http://localhost:5173`

应该能看到：
- 标题："Lin"
- 消息："Hello World！"（绿色文字）

---

## 停止服务

- **后端：** 在运行 `python main.py` 的终端按 `Ctrl+C`
- **前端：** 在运行 `npm run dev` 的终端按 `Ctrl+C`

---

## 常见问题

### 问题1：端口被占用

**后端端口 8000 被占用：**
```powershell
# 查看占用端口的进程
netstat -ano | findstr :8000

# 或使用其他端口
$env:PORT="8001"
python main.py
```

**前端端口 5173 被占用：**
Vite 会自动尝试下一个可用端口（5174, 5175...）

### 问题2：虚拟环境未激活

```powershell
# 激活虚拟环境
cd backend
..\venv\Scripts\activate

# 如果激活失败，检查虚拟环境是否存在
Test-Path venv\Scripts\activate
```

### 问题3：依赖未安装

**后端：**
```powershell
cd backend
..\venv\Scripts\activate
pip install -r requirements.txt
```

**前端：**
```powershell
cd frontend
npm install
```

---

## 开发提示

1. **热重载：** 
   - 前端：修改 Vue 文件后自动刷新
   - 后端：修改 Python 文件后需要手动重启

2. **查看日志：**
   - 后端日志在终端显示
   - 前端日志在浏览器控制台（F12）

3. **API 测试：**
   - 使用 http://127.0.0.1:8000/docs 测试 API
   - 这是 FastAPI 自动生成的交互式文档

