# Milvus 和 Attu 快速部署指南（阿里云）

## 🚀 一键部署（最简单）

在阿里云服务器上执行：

```bash
cd /var/www/my-fullstack-app
git pull gitee main
chmod +x deploy/deploy-milvus-aliyun-complete.sh
sudo ./deploy/deploy-milvus-aliyun-complete.sh
```

这个脚本会自动完成：
- ✅ 安装 Docker（使用阿里云镜像源）
- ✅ 安装 Docker Compose
- ✅ 配置防火墙
- ✅ 创建部署目录
- ✅ 启动 Milvus 和 Attu 服务

## 📋 部署后验证

```bash
# 验证部署状态
chmod +x deploy/verify-milvus-deployment.sh
./deploy/verify-milvus-deployment.sh
```

## 🌐 访问服务

部署完成后，可以通过以下地址访问：

- **Attu 管理界面**: `http://YOUR_SERVER_IP:3000`
- **Milvus API**: `YOUR_SERVER_IP:19530`
- **MinIO 控制台**: `http://YOUR_SERVER_IP:9001`

### 首次访问 Attu

1. 打开浏览器访问 `http://YOUR_SERVER_IP:3000`
2. 在连接页面填写：
   - **Milvus 地址**: `localhost:19530` 或 `YOUR_SERVER_IP:19530`
   - **用户名**: 留空
   - **密码**: 留空
3. 点击连接

## 🔧 服务管理

```bash
cd /opt/milvus

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f standalone  # Milvus
docker-compose logs -f attu         # Attu

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 停止并删除数据（谨慎操作）
docker-compose down -v
```

## 🔥 配置防火墙

如果无法访问服务，请配置防火墙：

```bash
chmod +x deploy/configure-firewall.sh
sudo ./deploy/configure-firewall.sh
```

或者手动配置阿里云安全组：
1. 登录阿里云控制台
2. 进入 ECS -> 安全组
3. 添加入方向规则：
   - 端口 3000 (Attu)
   - 端口 19530 (Milvus)
   - 端口 9000 (MinIO API)
   - 端口 9001 (MinIO Console)

## 🌍 配置域名访问（可选）

如果需要通过域名访问 Attu：

```bash
# 1. 复制 Nginx 配置
sudo cp deploy/nginx-attu.conf /etc/nginx/conf.d/attu.conf

# 2. 编辑配置文件，修改 server_name
sudo nano /etc/nginx/conf.d/attu.conf

# 3. 测试并重启 Nginx
sudo nginx -t
sudo systemctl restart nginx
```

## ❓ 常见问题

### 1. 端口无法访问

**检查步骤：**
```bash
# 检查服务是否运行
cd /opt/milvus && docker-compose ps

# 检查端口是否监听
sudo netstat -tlnp | grep 3000
sudo netstat -tlnp | grep 19530

# 检查防火墙
sudo firewall-cmd --list-ports

# 配置防火墙
sudo ./deploy/configure-firewall.sh
```

**解决方案：**
- 确保阿里云安全组已开放相应端口
- 运行防火墙配置脚本
- 检查服务是否正常运行

### 2. 服务启动失败

**查看日志：**
```bash
cd /opt/milvus
docker-compose logs -f
```

**常见原因：**
- 内存不足（Milvus 需要至少 2GB 内存）
- 端口被占用
- Docker 镜像下载失败

**解决方案：**
```bash
# 检查内存
free -h

# 检查端口占用
sudo netstat -tlnp | grep 19530

# 重新下载镜像
docker-compose pull
docker-compose up -d
```

### 3. Attu 无法连接 Milvus

**检查：**
- 确保 Milvus 服务正常运行：`docker-compose ps`
- 在 Attu 中填写正确的 Milvus 地址：
  - 容器内：`milvus-standalone:19530`
  - 外部：`localhost:19530` 或 `YOUR_SERVER_IP:19530`

### 4. Docker 镜像下载慢

脚本已自动配置阿里云镜像加速。如果仍有问题：

```bash
# 检查 Docker 镜像加速配置
cat /etc/docker/daemon.json

# 应该包含：
# {
#   "registry-mirrors": [
#     "https://registry.cn-hangzhou.aliyuncs.com",
#     "https://docker.mirrors.ustc.edu.cn"
#   ]
# }
```

## 📚 更多信息

- 详细部署指南：`DEPLOY_MILVUS_ALIYUN.md`
- 通用部署指南：`DEPLOY_MILVUS.md`
- [Milvus 官方文档](https://milvus.io/docs)
- [Attu 官方文档](https://github.com/zilliztech/attu)

## 🔐 安全建议

1. **修改 MinIO 默认密码**
   - 编辑 `/opt/milvus/docker-compose.yml`
   - 修改 `MINIO_ACCESS_KEY` 和 `MINIO_SECRET_KEY`

2. **配置防火墙规则**
   - 限制访问来源 IP
   - 只开放必要的端口

3. **使用 Nginx 反向代理**
   - 配置 SSL 证书
   - 隐藏内部端口

4. **定期备份数据**
   ```bash
   sudo tar -czf milvus-backup-$(date +%Y%m%d).tar.gz /opt/milvus/volumes/
   ```

