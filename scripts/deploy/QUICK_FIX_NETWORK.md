# 快速解决网络超时问题

## 问题
Docker 镜像拉取超时，即使配置了镜像加速仍然失败。

## 解决方案

### 方法 1: 使用可靠启动脚本（推荐）

```bash
cd /var/www/my-fullstack-app
git pull gitee main

# 使用可靠启动脚本（先拉取镜像，再启动服务）
chmod +x scripts/deploy/start-milvus-reliable.sh
sudo ./scripts/deploy/start-milvus-reliable.sh
```

### 方法 2: 先手动拉取镜像，再启动

```bash
cd /var/www/my-fullstack-app
git pull gitee main

# 1. 确保镜像加速已配置
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://jgz5n894.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
sleep 5

# 2. 使用重试脚本拉取镜像
chmod +x scripts/deploy/pull-images-with-retry.sh
sudo ./scripts/deploy/pull-images-with-retry.sh

# 3. 启动服务
cd /opt/milvus
sudo docker compose up -d

# 4. 检查状态
sleep 30
sudo docker ps --filter "name=milvus"
```

### 方法 3: 逐个手动拉取（最可靠）

```bash
# 配置镜像加速
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://jgz5n894.mirror.aliyuncs.com"]
}
EOF
sudo systemctl restart docker
sleep 5

# 逐个拉取镜像（每个都有 10 分钟超时）
echo "拉取 etcd..."
timeout 600 docker pull quay.io/coreos/etcd:v3.5.5 || echo "etcd 拉取失败"

echo "拉取 minio..."
timeout 600 docker pull minio/minio:RELEASE.2023-03-20T20-16-18Z || echo "minio 拉取失败"

echo "拉取 milvus..."
timeout 600 docker pull milvusdb/milvus:v2.3.3 || echo "milvus 拉取失败"

echo "拉取 attu..."
timeout 600 docker pull zilliz/attu:v2.3.0 || echo "attu 拉取失败"

# 启动服务
cd /opt/milvus
sudo docker compose up -d
```

### 方法 4: 检查并修复网络问题

```bash
# 1. 验证镜像加速配置
cat /etc/docker/daemon.json

# 2. 测试镜像加速是否工作
docker pull hello-world

# 3. 如果仍然超时，检查网络
ping registry-1.docker.io
ping jgz5n894.mirror.aliyuncs.com

# 4. 检查 Docker 日志
sudo journalctl -u docker -n 50

# 5. 重启 Docker
sudo systemctl restart docker
```

## 关键点

1. **增加超时时间**: 使用 `timeout 600` 给每个镜像 10 分钟拉取时间
2. **重试机制**: 失败后自动重试，最多 5 次
3. **先拉取后启动**: 先确保所有镜像都拉取成功，再启动服务
4. **验证配置**: 确保镜像加速配置正确并已重启 Docker

## 如果仍然失败

1. 检查服务器网络连接
2. 检查防火墙是否阻止了 Docker 端口
3. 尝试使用其他镜像加速源
4. 考虑使用代理或 VPN

