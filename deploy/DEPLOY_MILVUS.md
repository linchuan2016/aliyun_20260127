# Milvus 和 Attu 部署指南

本指南介绍如何在阿里云服务器上部署 Milvus 向量数据库和 Attu 管理界面。

## 前置要求

- 阿里云服务器（建议至少 2GB 内存）
- Docker 和 Docker Compose 已安装
- 开放端口：19530 (Milvus), 3000 (Attu), 9000/9001 (MinIO)

## 快速部署

### 方法一：一键快速部署（最简单）

```bash
# 1. 将项目代码同步到服务器
cd /var/www/my-fullstack-app
git pull gitee main

# 2. 执行一键部署脚本（会自动安装 Docker 和 Docker Compose）
chmod +x deploy/quick-deploy-milvus.sh
sudo ./deploy/quick-deploy-milvus.sh
```

### 方法二：使用部署脚本（已安装 Docker）

```bash
# 1. 将项目代码同步到服务器
cd /var/www/my-fullstack-app
git pull gitee main

# 2. 执行部署脚本
chmod +x deploy/deploy-milvus.sh
sudo ./deploy/deploy-milvus.sh
```

### 方法二：手动部署

```bash
# 1. 创建部署目录
sudo mkdir -p /opt/milvus
sudo mkdir -p /opt/milvus/volumes/{etcd,minio,milvus}

# 2. 复制 docker-compose.yml
sudo cp /var/www/my-fullstack-app/deploy/milvus-docker-compose.yml /opt/milvus/docker-compose.yml

# 3. 设置权限
sudo chown -R $USER:$USER /opt/milvus
sudo chmod -R 755 /opt/milvus

# 4. 启动服务
cd /opt/milvus
docker-compose up -d

# 5. 检查服务状态
docker-compose ps
```

## 安装 Docker 和 Docker Compose

如果服务器上还没有安装 Docker：

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | bash
sudo systemctl start docker
sudo systemctl enable docker

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker --version
docker-compose --version
```

## 配置防火墙

```bash
# 开放 Milvus 端口
sudo firewall-cmd --permanent --add-port=19530/tcp
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --permanent --add-port=9001/tcp
sudo firewall-cmd --reload

# 或者使用 iptables
sudo iptables -A INPUT -p tcp --dport 19530 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 9000 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 9001 -j ACCEPT
```

## 配置 Nginx 反向代理（可选）

如果需要通过域名访问 Attu，可以配置 Nginx：

```nginx
# /etc/nginx/conf.d/milvus-attu.conf
server {
    listen 80;
    server_name attu.linchuan.tech;  # 替换为你的域名

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

然后重启 Nginx：

```bash
sudo nginx -t
sudo systemctl restart nginx
```

## 服务管理

### 查看服务状态

```bash
cd /opt/milvus
docker-compose ps
```

### 查看服务日志

```bash
# 查看所有服务日志
cd /opt/milvus
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f standalone  # Milvus
docker-compose logs -f attu        # Attu
```

### 重启服务

```bash
cd /opt/milvus
docker-compose restart
```

### 停止服务

```bash
cd /opt/milvus
docker-compose down
```

### 停止并删除数据（谨慎操作）

```bash
cd /opt/milvus
docker-compose down -v
```

## 访问服务

### Milvus API

- 地址: `localhost:19530` 或 `YOUR_SERVER_IP:19530`
- 用于应用程序连接

### Attu 管理界面

- 地址: `http://YOUR_SERVER_IP:3000`
- 或通过域名: `http://attu.linchuan.tech`（如果配置了 Nginx）

首次访问 Attu 时，需要：
1. 输入 Milvus 地址: `milvus-standalone:19530`（容器内）或 `localhost:19530`（外部）
2. 用户名和密码留空（默认配置）

## 验证部署

```bash
# 检查容器是否运行
docker ps | grep milvus

# 检查端口是否监听
sudo netstat -tlnp | grep 19530
sudo netstat -tlnp | grep 3000

# 测试 Milvus 连接（需要安装 pymilvus）
python3 -c "from pymilvus import connections; connections.connect(host='localhost', port='19530'); print('连接成功')"
```

## 常见问题

### 1. 端口被占用

```bash
# 检查端口占用
sudo netstat -tlnp | grep 19530
sudo netstat -tlnp | grep 3000

# 修改 docker-compose.yml 中的端口映射
```

### 2. 内存不足

Milvus 需要至少 2GB 内存，如果内存不足：

```bash
# 检查内存使用
free -h

# 可以调整 docker-compose.yml 中的资源限制
```

### 3. 数据持久化

数据存储在 `/opt/milvus/volumes/` 目录下，确保定期备份：

```bash
# 备份数据
sudo tar -czf milvus-backup-$(date +%Y%m%d).tar.gz /opt/milvus/volumes/
```

## 更新 Milvus

```bash
cd /opt/milvus
docker-compose pull
docker-compose up -d
```

## 安全建议

1. 修改 MinIO 默认密码（在 docker-compose.yml 中）
2. 配置防火墙规则，限制访问来源
3. 使用 Nginx 反向代理并配置 SSL
4. 定期备份数据

## 相关链接

- [Milvus 官方文档](https://milvus.io/docs)
- [Attu 官方文档](https://github.com/zilliztech/attu)
- [Docker Compose 文档](https://docs.docker.com/compose/)

