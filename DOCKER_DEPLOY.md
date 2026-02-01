# Docker 部署指南

## 📋 核心步骤概览

### 1. 前置要求
- ✅ 安装 Docker Desktop（Windows/Mac）或 Docker Engine（Linux）
- ✅ 安装 docker-compose（Docker Desktop 已包含）

### 2. 快速启动（3 步）

```bash
# 步骤 1: 复制环境变量文件
cp env.example .env

# 步骤 2: 构建并启动（Windows PowerShell）
.\docker-start.ps1

# 或 Linux/Mac
chmod +x docker-start.sh
./docker-start.sh

# 步骤 3: 访问服务
# 后端: http://localhost:8000
# 前端: http://localhost:5173
```

### 3. 手动启动（详细步骤）

```bash
# 1. 创建环境变量文件
cp env.example .env

# 2. 构建镜像
docker-compose build

# 3. 启动服务
docker-compose up -d

# 4. 查看日志
docker-compose logs -f

# 5. 停止服务
docker-compose down
```

---

## 🏗️ 架构说明

### 服务组成

```
┌─────────────────┐
│   Frontend      │  Vue 3 + Vite (Nginx)
│   Port: 5173    │
└────────┬────────┘
         │
         │ HTTP
         │
┌────────▼────────┐
│   Backend       │  FastAPI + Python
│   Port: 8000    │
└────────┬────────┘
         │
         │ SQLite/MySQL
         │
┌────────▼────────┐
│   Data Volume   │  ./data (数据库 + 图片)
└─────────────────┘
```

### 数据持久化

- **数据库文件**: `./data/products.db` (SQLite)
- **图片文件**: `./data/article-covers/`, `./data/book-covers/`
- 使用 Docker volume 挂载，数据保存在宿主机

---

## 🔧 配置说明

### 环境变量 (.env)

```bash
# 数据库配置
DATABASE_URL=sqlite:////app/data/products.db

# 后端服务
HOST=0.0.0.0
PORT=8000

# CORS 配置
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

### 端口映射

- **后端**: `8000:8000` (宿主机:容器)
- **前端**: `5173:80` (宿主机:容器)

---

## 📝 常用命令

### 服务管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f [service_name]

# 查看后端日志
docker-compose logs -f backend

# 查看前端日志
docker-compose logs -f frontend
```

### 镜像管理

```bash
# 重新构建镜像
docker-compose build

# 强制重新构建（不使用缓存）
docker-compose build --no-cache

# 删除所有容器和镜像
docker-compose down --rmi all
```

### 进入容器

```bash
# 进入后端容器
docker-compose exec backend bash

# 进入前端容器
docker-compose exec frontend sh

# 执行命令
docker-compose exec backend python init_db.py
```

---

## 🐛 故障排查

### 1. 端口被占用

```bash
# 检查端口占用
netstat -ano | findstr :8000  # Windows
lsof -i :8000                 # Linux/Mac

# 修改 docker-compose.yml 中的端口映射
ports:
  - "8001:8000"  # 改为其他端口
```

### 2. 数据目录权限问题

```bash
# Linux/Mac: 确保数据目录可写
chmod -R 755 data/

# Windows: 确保 Docker Desktop 有权限访问目录
```

### 3. 后端服务无法启动

```bash
# 查看详细日志
docker-compose logs backend

# 检查数据库文件权限
docker-compose exec backend ls -la /app/data

# 手动初始化数据库
docker-compose exec backend python init_db.py
```

### 4. 前端无法访问后端 API

```bash
# 检查 CORS 配置
# 在 .env 中添加前端地址到 ALLOWED_ORIGINS

# 检查网络连接
docker-compose exec frontend ping backend
```

### 5. 镜像构建失败

```bash
# 清理缓存重新构建
docker-compose build --no-cache

# 检查 Dockerfile 语法
docker build -t test ./backend
```

---

## 🚀 生产环境部署

### 1. 使用 MySQL（推荐）

修改 `docker-compose.yml`:

```yaml
services:
  mysql:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: your_password
      MYSQL_DATABASE: myapp
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - app-network

  backend:
    environment:
      - DATABASE_URL=mysql+pymysql://root:your_password@mysql:3306/myapp
    depends_on:
      - mysql
```

### 2. 添加 Nginx 反向代理

取消注释 `docker-compose.yml` 中的 nginx 服务，配置 SSL 证书。

### 3. 数据备份

```bash
# 备份数据库
docker-compose exec backend cp /app/data/products.db /app/data/products.db.backup

# 备份整个数据目录
tar -czf data-backup.tar.gz data/
```

---

## 📊 监控和健康检查

### 健康检查端点

- 后端: `http://localhost:8000/api/health`

### 查看容器资源使用

```bash
docker stats
```

---

## 🔄 更新部署

```bash
# 1. 拉取最新代码
git pull

# 2. 重新构建镜像
docker-compose build

# 3. 重启服务（零停机）
docker-compose up -d

# 或强制重新创建
docker-compose up -d --force-recreate
```

---

## 📚 相关文件

- `docker-compose.yml` - Docker Compose 配置
- `backend/Dockerfile` - 后端镜像构建文件
- `frontend/Dockerfile` - 前端镜像构建文件
- `.dockerignore` - Docker 构建忽略文件
- `.env.example` - 环境变量模板

---

## ⚠️ 注意事项

1. **数据持久化**: 确保 `data/` 目录有正确的权限
2. **环境变量**: 生产环境必须修改 `.env` 中的敏感信息
3. **端口冲突**: 确保 8000 和 5173 端口未被占用
4. **资源限制**: 根据服务器配置调整 `docker-compose.yml` 中的资源限制

---

## 🆘 获取帮助

- 查看日志: `docker-compose logs -f`
- 检查状态: `docker-compose ps`
- 查看文档: `http://localhost:8000/docs`

