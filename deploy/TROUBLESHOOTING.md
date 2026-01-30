# Milvus 部署故障排查指南

## 内存不足问题

### 问题：安装 Docker 时进程被 "Killed"

**症状：**
- 执行 `yum install` 时进程被终止
- 错误信息：`Killed` 或 `Out of memory`

**原因：**
- 服务器内存不足（通常小于 1GB）
- 安装依赖时内存占用过高

**解决方案：**

#### 方案 1: 使用低内存优化脚本（推荐）

```bash
cd /var/www/my-fullstack-app
chmod +x deploy/install-docker-aliyun-low-memory.sh
sudo ./deploy/install-docker-aliyun-low-memory.sh
```

#### 方案 2: 使用 Docker 官方安装脚本

```bash
# 使用阿里云镜像的官方安装脚本
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 配置镜像加速
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": [
    "https://registry.cn-hangzhou.aliyuncs.com",
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
EOF

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker
```

#### 方案 3: 释放内存后再安装

```bash
# 1. 检查内存使用
free -h

# 2. 停止不必要的服务
sudo systemctl stop <service-name>

# 3. 清理缓存
sudo sync
sudo echo 3 > /proc/sys/vm/drop_caches

# 4. 再次尝试安装
sudo ./deploy/install-docker-aliyun.sh
```

#### 方案 4: 增加交换空间（Swap）

```bash
# 创建 2GB 交换文件
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 永久启用（添加到 /etc/fstab）
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab

# 验证
free -h

# 然后重新安装 Docker
sudo ./deploy/install-docker-aliyun.sh
```

### 问题：Milvus 启动失败

**症状：**
- 容器启动后立即退出
- 日志显示内存不足

**解决方案：**

1. **检查内存**
   ```bash
   free -h
   ```
   Milvus 需要至少 2GB 内存

2. **增加交换空间**（见上方方案 4）

3. **调整 Docker 资源限制**
   编辑 `/opt/milvus/docker-compose.yml`，添加资源限制：
   ```yaml
   standalone:
     # ... 其他配置
     deploy:
       resources:
         limits:
           memory: 1.5G
         reservations:
           memory: 1G
   ```

## 端口被占用

### 问题：端口 3000 或 19530 已被占用

**检查端口占用：**
```bash
sudo netstat -tlnp | grep 3000
sudo netstat -tlnp | grep 19530
```

**解决方案：**

1. **停止占用端口的服务**
   ```bash
   sudo kill -9 <PID>
   ```

2. **修改 docker-compose.yml 中的端口映射**
   ```yaml
   ports:
     - "3001:3000"  # 改为其他端口
     - "19531:19530"
   ```

## 网络问题

### 问题：无法拉取 Docker 镜像

**解决方案：**

1. **检查镜像加速配置**
   ```bash
   cat /etc/docker/daemon.json
   ```

2. **重新配置镜像加速**
   ```bash
   sudo mkdir -p /etc/docker
   sudo tee /etc/docker/daemon.json <<-'EOF'
   {
     "registry-mirrors": [
       "https://registry.cn-hangzhou.aliyuncs.com",
       "https://docker.mirrors.ustc.edu.cn"
     ]
   }
   EOF
   sudo systemctl restart docker
   ```

3. **手动拉取镜像**
   ```bash
   docker pull milvusdb/milvus:v2.3.3
   docker pull zilliz/attu:v2.3.0
   ```

## 权限问题

### 问题：Permission denied

**解决方案：**

```bash
# 将用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker

# 或者使用 sudo 运行命令
sudo docker ps
```

## 服务无法启动

### 问题：容器启动后立即退出

**检查日志：**
```bash
cd /opt/milvus
docker-compose logs -f
```

**常见原因和解决方案：**

1. **依赖服务未就绪**
   - 等待更长时间：`sleep 30`
   - 检查 etcd 和 minio 是否正常

2. **数据目录权限问题**
   ```bash
   sudo chown -R $USER:$USER /opt/milvus/volumes
   ```

3. **配置文件错误**
   ```bash
   # 验证 docker-compose.yml
   docker-compose config
   ```

## 防火墙问题

### 问题：无法从外部访问服务

**检查步骤：**

1. **检查本地防火墙**
   ```bash
   sudo firewall-cmd --list-ports
   sudo ./deploy/configure-firewall.sh
   ```

2. **检查阿里云安全组**
   - 登录阿里云控制台
   - ECS -> 安全组 -> 配置规则
   - 确保已开放端口 3000 和 19530

3. **检查服务是否监听**
   ```bash
   sudo netstat -tlnp | grep 3000
   sudo netstat -tlnp | grep 19530
   ```

## 获取更多帮助

如果以上方案都无法解决问题：

1. **收集诊断信息**
   ```bash
   # 系统信息
   uname -a
   free -h
   df -h
   
   # Docker 信息
   docker --version
   docker-compose --version
   docker ps -a
   
   # 服务日志
   cd /opt/milvus
   docker-compose logs > milvus-logs.txt
   ```

2. **运行验证脚本**
   ```bash
   ./deploy/verify-milvus-deployment.sh
   ```

3. **查看详细文档**
   - `DEPLOY_MILVUS_ALIYUN.md`
   - `QUICK_START_MILVUS.md`

