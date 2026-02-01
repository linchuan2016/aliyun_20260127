# 🚀 Docker 启动指南 - 3步启动

## ✅ 步骤 1: 准备环境变量（已完成）
```powershell
Copy-Item env.example .env
```
✓ `.env` 文件已创建

---

## 🎯 步骤 2: 启动服务

现在执行启动脚本：

```powershell
.\docker-start.ps1
```

这个脚本会：
1. 检查 Docker 环境
2. 构建 Docker 镜像（首次需要几分钟）
3. 启动所有服务
4. 验证服务状态

---

## 🌐 步骤 3: 访问服务

启动成功后，访问以下地址：

- **前端应用**: http://localhost:5173
- **后端 API**: http://localhost:8000
- **API 文档**: http://localhost:8000/docs

---

## 📋 执行步骤 2

请在 PowerShell 中运行：

```powershell
.\docker-start.ps1
```

---

## ⚠️ 注意事项

1. **首次构建**：需要下载镜像和依赖，可能需要 5-10 分钟
2. **端口占用**：确保 8000 和 5173 端口未被占用
3. **数据目录**：`./data` 目录会自动创建

---

## 🔍 如果遇到问题

### 查看日志
```powershell
docker-compose logs -f
```

### 查看服务状态
```powershell
docker-compose ps
```

### 重新构建（如果构建失败）
```powershell
docker-compose build --no-cache
docker-compose up -d
```

---

## ✅ 验证部署

启动后，测试后端：
```powershell
curl http://localhost:8000/api/health
```

应该返回：`{"status":"ok"}`

