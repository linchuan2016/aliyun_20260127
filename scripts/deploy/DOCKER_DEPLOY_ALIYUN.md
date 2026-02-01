# 🚀 阿里云 Docker 部署指南

## 📋 前置要求

1. **阿里云 ECS 服务器**（建议配置）：
   - CPU: 2核或以上
   - 内存: 4GB 或以上（Milvus 需要较多内存）
   - 系统: CentOS 7/8 或 Ubuntu 18.04+
   - 磁盘: 至少 20GB 可用空间

2. **网络要求**：
   - 开放端口: 80, 443, 8000, 5173, 3000（可选）
   - 确保可以访问 Docker Hub 或配置镜像加速

## 🎯 部署步骤

### 方式一：完整部署（首次部署推荐）

在阿里云服务器上执行：

```bash
# 1. 进入项目目录
cd /var/www/my-fullstack-app

# 2. 拉取最新代码
git pull

# 3. 执行完整部署脚本
sudo bash scripts/deploy/deploy-docker-aliyun.sh
```

这个脚本会自动：
- ✅ 检查并安装 Docker
- ✅ 检查并安装 Docker Compose
- ✅ 创建必要的目录
- ✅ 配置环境变量
- ✅ 构建并启动所有服务
- ✅ 初始化数据库
- ✅ 配置 Nginx（可选）
- ✅ 配置防火墙（可选）
- ✅ 验证部署

### 方式二：快速部署（已安装 Docker）

如果服务器已安装 Docker 和 Docker Compose：

```bash
cd /var/www/my-fullstack-app
git pull
sudo bash scripts/deploy/deploy-docker-aliyun-quick.sh
```

## 📝 部署后配置

### 1. 修改环境变量

编辑 `.env` 文件，根据实际情况修改：

```bash
nano /var/www/my-fullstack-app/.env
```

重要配置项：
- `ALLOWED_ORIGINS`: 添加实际访问的域名/IP
- `SECRET_KEY`: 生产环境请修改为强密钥

### 2. 配置 Nginx（如果使用系统 Nginx）

如果选择配置 Nginx，脚本会自动创建配置文件。需要手动修改域名：

```bash
sudo nano /etc/nginx/conf.d/my-fullstack-app.conf
```

将 `server_name _;` 改为实际域名或 IP。

### 3. 配置 SSL（HTTPS，可选）

如果需要 HTTPS：

```bash
# 安装 Certbot
sudo yum install -y certbot python3-certbot-nginx  # CentOS
# 或
sudo apt-get install -y certbot python3-certbot-nginx  # Ubuntu

# 申请证书
sudo certbot --nginx -d your-domain.com
```

## 🔍 验证部署

### 检查服务状态

```bash
cd /var/www/my-fullstack-app
docker-compose ps
```

所有服务应该显示为 `Up` 状态。

### 测试服务

```bash
# 测试后端
curl http://localhost:8000/api/health

# 测试前端
curl http://localhost:5173

# 查看日志
docker-compose logs -f
```

### 访问服务

- **前端应用**: `http://your-server-ip:5173`
- **后端 API**: `http://your-server-ip:8000`
- **API 文档**: `http://your-server-ip:8000/docs`
- **Attu 管理**: `http://your-server-ip:5173/attu`（需要登录）

## 🛠️ 常用命令

### 服务管理

```bash
cd /var/www/my-fullstack-app

# 启动服务
docker-compose up -d

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 查看日志
docker-compose logs -f
docker-compose logs -f backend  # 只看后端日志
docker-compose logs -f frontend  # 只看前端日志

# 查看服务状态
docker-compose ps
```

### 更新代码

```bash
cd /var/www/my-fullstack-app

# 拉取最新代码
git pull

# 重新构建并启动
docker-compose up -d --build

# 或者使用快速部署脚本
sudo bash scripts/deploy/deploy-docker-aliyun-quick.sh
```

### 数据备份

```bash
# 备份数据目录
tar -czf data-backup-$(date +%Y%m%d).tar.gz /var/www/my-fullstack-app/data

# 备份数据库
docker-compose exec backend python -c "
import sqlite3
import shutil
shutil.copy('/app/data/products.db', '/app/data/products.db.backup')
"
```

## ⚠️ 注意事项

1. **内存要求**：
   - Milvus 需要至少 2GB 内存
   - 建议总内存 4GB 或以上
   - 如果内存不足，可以禁用 Milvus 相关服务

2. **端口占用**：
   - 确保 8000, 5173, 3000 端口未被占用
   - 如果使用系统 Nginx，确保 80, 443 端口可用

3. **数据持久化**：
   - 数据存储在 `./data` 目录
   - 确保该目录有写权限
   - 定期备份数据

4. **防火墙配置**：
   - 阿里云安全组需要开放相应端口
   - 系统防火墙也需要配置（脚本会自动处理）

5. **性能优化**：
   - 生产环境建议使用 Docker 镜像加速
   - 可以配置 Docker 资源限制
   - 建议使用 SSD 存储

## 🐛 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker-compose logs backend
docker-compose logs frontend

# 检查容器状态
docker-compose ps

# 检查资源使用
docker stats
```

### 端口冲突

```bash
# 检查端口占用
netstat -tulpn | grep -E '8000|5173|3000'

# 修改 docker-compose.yml 中的端口映射
```

### 内存不足

```bash
# 查看内存使用
free -h

# 如果内存不足，可以：
# 1. 禁用 Milvus 相关服务
# 2. 增加服务器内存
# 3. 优化 Docker 配置
```

### 数据库问题

```bash
# 重新初始化数据库
docker-compose exec backend python init_db.py

# 检查数据库文件权限
ls -la /var/www/my-fullstack-app/data/
```

## 📞 支持

如果遇到问题，请检查：
1. 服务日志: `docker-compose logs -f`
2. 系统资源: `free -h`, `df -h`
3. 网络连接: `curl http://localhost:8000/api/health`

## ✅ 部署检查清单

- [ ] Docker 已安装并运行
- [ ] Docker Compose 已安装
- [ ] 代码已同步到服务器
- [ ] 环境变量已配置
- [ ] 数据目录已创建并有写权限
- [ ] 所有服务正常运行
- [ ] 后端 API 可访问
- [ ] 前端应用可访问
- [ ] Nginx 已配置（如需要）
- [ ] 防火墙已配置
- [ ] SSL 证书已配置（如需要）

