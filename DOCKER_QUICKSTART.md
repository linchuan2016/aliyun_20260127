# 🚀 Docker 快速启动指南

## ⚡ 核心步骤（3步启动）

### 步骤 1: 准备环境变量
```powershell
# Windows PowerShell
Copy-Item env.example .env
```

```bash
# Linux/Mac
cp env.example .env
```

### 步骤 2: 启动服务
```powershell
# Windows PowerShell
.\docker-start.ps1
```

```bash
# Linux/Mac
chmod +x docker-start.sh
./docker-start.sh
```

### 步骤 3: 访问服务
- 🌐 **前端**: http://localhost:5173
- 🔧 **后端 API**: http://localhost:8000
- 📚 **API 文档**: http://localhost:8000/docs

---

## 📋 手动启动（如果脚本失败）

```bash
# 1. 构建镜像
docker-compose build

# 2. 启动服务
docker-compose up -d

# 3. 查看日志
docker-compose logs -f

# 4. 停止服务
docker-compose down
```

---

## 🏗️ 架构说明

```
┌─────────────┐
│  Frontend   │  Vue 3 (Nginx) - Port 5173
│  (Nginx)    │
└──────┬──────┘
       │
       │ /api/* → 代理到后端
       │
┌──────▼──────┐
│  Backend    │  FastAPI - Port 8000
│  (Python)   │
└──────┬──────┘
       │
       │ SQLite
       │
┌──────▼──────┐
│  Data       │  ./data/products.db
│  (Volume)   │  ./data/*-covers/
└─────────────┘
```

---

## 🔍 核心文件说明

| 文件 | 说明 |
|------|------|
| `docker-compose.yml` | 服务编排配置 |
| `backend/Dockerfile` | 后端镜像构建 |
| `frontend/Dockerfile` | 前端镜像构建 |
| `frontend/nginx.conf` | 前端 Nginx 配置（API 代理）|
| `.env` | 环境变量（从 env.example 复制）|
| `.dockerignore` | Docker 构建忽略文件 |

---

## ⚙️ 关键配置

### 数据持久化
- 数据库: `./data/products.db` → `/app/data/products.db`
- 图片: `./data/*-covers/` → `/app/data/*-covers/`

### 端口映射
- 前端: `5173:80` (宿主机:容器)
- 后端: `8000:8000`

### 网络
- 服务间通过 Docker 网络通信
- 前端通过 `http://backend:8000` 访问后端

---

## 🐛 常见问题

### 1. Docker 未安装
- Windows/Mac: 下载 [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Linux: `sudo apt-get install docker.io docker-compose`

### 2. 端口被占用
修改 `docker-compose.yml` 中的端口：
```yaml
ports:
  - "8001:8000"  # 改为其他端口
```

### 3. 数据目录权限
```bash
# Linux/Mac
chmod -R 755 data/

# Windows: 确保 Docker Desktop 有权限访问目录
```

### 4. 查看日志
```bash
# 所有服务
docker-compose logs -f

# 特定服务
docker-compose logs -f backend
docker-compose logs -f frontend
```

---

## 📝 常用命令

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 重启
docker-compose restart

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 进入容器
docker-compose exec backend bash
docker-compose exec frontend sh

# 重新构建
docker-compose build --no-cache
```

---

## ✅ 验证部署

1. **检查服务状态**
   ```bash
   docker-compose ps
   ```
   应该看到 `backend` 和 `frontend` 都是 `Up` 状态

2. **测试后端**
   ```bash
   curl http://localhost:8000/api/health
   ```
   应该返回: `{"status":"ok"}`

3. **测试前端**
   浏览器访问: http://localhost:5173

4. **检查数据**
   ```bash
   ls -la data/
   ```
   应该看到 `products.db` 和图片目录

---

## 🎯 下一步

- 📖 查看详细文档: [DOCKER_DEPLOY.md](./DOCKER_DEPLOY.md)
- 🔧 配置生产环境: 修改 `.env` 文件
- 🚀 部署到阿里云: 参考部署文档

