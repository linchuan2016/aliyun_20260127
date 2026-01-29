# 阿里云服务器 Milvus 部署指南（解决网络问题）

如果遇到 Docker 安装网络问题，请按照以下步骤操作。

## 方法一：手动安装 Docker（推荐）

### 1. 安装 Docker

```bash
# 卸载旧版本（如果有）
sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

# 安装依赖
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

# 添加 Docker 仓库（使用阿里云镜像）
sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# 安装 Docker
sudo yum install -y docker-ce docker-ce-cli containerd.io

# 配置 Docker 镜像加速
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
sudo systemctl daemon-reload
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
sudo docker --version
sudo docker run hello-world
```

### 2. 安装 Docker Compose

```bash
# 下载 Docker Compose（使用 GitHub 直接下载）
COMPOSE_VERSION="2.20.0"
ARCH=$(uname -m)  # 通常是 x86_64 或 aarch64

sudo curl -L "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${ARCH}" -o /usr/local/bin/docker-compose

# 如果 curl 失败，使用 wget
# sudo wget -O /usr/local/bin/docker-compose "https://github.com/docker/compose/releases/download/v${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"

# 设置权限
sudo chmod +x /usr/local/bin/docker-compose

# 创建软链接
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 验证安装
docker-compose --version
```

### 3. 部署 Milvus

```bash
# 同步代码
cd /var/www/my-fullstack-app
git pull gitee main

# 创建部署目录
sudo mkdir -p /opt/milvus/volumes/{etcd,minio,milvus}

# 复制配置文件
sudo cp deploy/milvus-docker-compose.yml /opt/milvus/docker-compose.yml

# 设置权限
sudo chown -R $USER:$USER /opt/milvus
sudo chmod -R 755 /opt/milvus

# 启动服务
cd /opt/milvus
docker-compose up -d

# 查看状态
docker-compose ps
```

## 方法二：使用安装脚本

如果项目中有安装脚本：

```bash
cd /var/www/my-fullstack-app
git pull gitee main

# 安装 Docker
chmod +x deploy/install-docker-aliyun.sh
sudo ./deploy/install-docker-aliyun.sh

# 安装 Docker Compose
chmod +x deploy/install-docker-compose.sh
sudo ./deploy/install-docker-compose.sh

# 部署 Milvus
chmod +x deploy/quick-deploy-milvus.sh
sudo ./deploy/quick-deploy-milvus.sh
```

## 如果 GitHub 访问困难

可以手动下载 Docker Compose：

```bash
# 1. 在本地下载 docker-compose 文件
# 访问: https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-linux-x86_64
# 下载后上传到服务器

# 2. 上传到服务器后
sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
```

## 验证部署

```bash
# 检查 Docker
sudo docker ps

# 检查 Milvus 服务
cd /opt/milvus
docker-compose ps

# 查看日志
docker-compose logs -f
```

## 访问服务

- **Attu 管理界面**: `http://YOUR_SERVER_IP:3000`
- **Milvus API**: `localhost:19530`

## 常见问题

### 1. SSL 连接错误

如果遇到 SSL 连接错误，可以：
- 使用阿里云镜像源（已在上面的脚本中配置）
- 检查防火墙设置
- 使用代理（如果有）

### 2. Docker 服务启动失败

```bash
# 检查 Docker 状态
sudo systemctl status docker

# 查看日志
sudo journalctl -u docker -n 50

# 重启 Docker
sudo systemctl restart docker
```

### 3. 权限问题

```bash
# 将当前用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录或执行
newgrp docker
```

