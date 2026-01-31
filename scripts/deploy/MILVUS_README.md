# Milvus 和 Attu 部署指南（阿里云）

## 快速启动

在阿里云服务器上执行：

```bash
cd /var/www/my-fullstack-app

# 1. 确保 Docker 已安装
docker --version

# 2. 启动 Milvus 和 Attu
chmod +x scripts/deploy/start-milvus.sh
sudo ./scripts/deploy/start-milvus.sh

# 3. 配置防火墙（如果需要）
chmod +x scripts/deploy/configure-milvus-firewall.sh
sudo ./scripts/deploy/configure-milvus-firewall.sh
```

## 访问服务

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

## 服务管理

```bash
cd /opt/milvus

# 查看服务状态
docker-compose ps
# 或
docker compose ps

# 查看日志
docker-compose logs -f
# 或
docker compose logs -f

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

## 配置阿里云安全组

在阿里云控制台配置安全组规则：

1. 登录阿里云控制台
2. 进入 ECS -> 安全组
3. 添加入方向规则：
   - 端口 3000 (Attu)
   - 端口 19530 (Milvus)
   - 端口 9000 (MinIO API)
   - 端口 9001 (MinIO Console)

## 故障排查

### 服务无法启动

```bash
# 查看详细日志
cd /opt/milvus
docker-compose logs -f

# 检查端口占用
sudo netstat -tlnp | grep 3000
sudo netstat -tlnp | grep 19530
```

### 端口无法访问

1. 检查防火墙配置
2. 检查阿里云安全组
3. 检查服务是否正常运行

### 内存不足

Milvus 需要至少 2GB 内存。如果内存不足：

```bash
# 检查内存
free -h

# 可以增加交换空间
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 数据备份

数据存储在 `/opt/milvus/volumes/` 目录：

```bash
# 备份数据
sudo tar -czf milvus-backup-$(date +%Y%m%d).tar.gz /opt/milvus/volumes/
```

