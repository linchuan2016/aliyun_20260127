# Alibaba Cloud Linux 快速部署指南

## ⚠️ 重要提示

**Alibaba Cloud Linux 使用 `yum` 命令，不是 `apt`！**

## 快速步骤

### 1. 上传代码到服务器

**⚠️ 重要：不要上传 `venv` 文件夹！必须在服务器上重新创建虚拟环境。**

```bash
# 方式一：使用 Git（推荐，自动排除 venv）
git clone <your-repo> /var/www/my-fullstack-app

# 方式二：使用 SCP（在本地 Windows PowerShell 执行）
# 先创建目录
ssh root@your-server-ip "mkdir -p /var/www/my-fullstack-app"

# 分别上传需要的文件夹（排除 venv）
scp -r D:\Aliyun\my-fullstack-app\backend root@your-server-ip:/var/www/my-fullstack-app/
scp -r D:\Aliyun\my-fullstack-app\frontend root@your-server-ip:/var/www/my-fullstack-app/
scp -r D:\Aliyun\my-fullstack-app\deploy root@your-server-ip:/var/www/my-fullstack-app/
```

### 2. 一键部署

```bash
cd /var/www/my-fullstack-app
chmod +x deploy/deploy.sh
sudo bash deploy/deploy.sh
```

### 3. 手动配置（如果一键部署失败）

```bash
# 1. 更新系统并安装依赖
sudo yum update -y
sudo yum install -y python3 python3-pip python3-devel nginx git

# 2. 安装 Node.js
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 3. 设置后端
cd /var/www/my-fullstack-app/backend
python3 -m venv ../venv
source ../venv/bin/activate
pip install -r requirements.txt

# 4. 构建前端
cd ../frontend
npm install
npm run build

# 5. 配置服务
sudo cp deploy/my-fullstack-app.service /etc/systemd/system/
sudo cp deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf

# 6. 编辑配置文件（修改域名）
sudo vi /etc/systemd/system/my-fullstack-app.service
sudo vi /etc/nginx/conf.d/my-fullstack-app.conf

# 7. 启动服务
sudo systemctl daemon-reload
sudo systemctl enable my-fullstack-app
sudo systemctl start my-fullstack-app
sudo systemctl restart nginx

# 8. 配置防火墙
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### 4. 配置阿里云安全组

在阿里云控制台 → 轻量应用服务器 → 防火墙：
- 开放端口 80（HTTP）
- 开放端口 443（HTTPS，可选）
- 开放端口 22（SSH）

### 5. 访问应用

浏览器访问：`http://your-domain.com` 或 `http://your-server-ip`

## 常用命令对比

| 操作 | Ubuntu | Alibaba Cloud Linux |
|-----|--------|-------------------|
| 更新系统 | `sudo apt update` | `sudo yum update` |
| 安装软件 | `sudo apt install` | `sudo yum install` |
| Nginx 配置目录 | `/etc/nginx/sites-available` | `/etc/nginx/conf.d` |
| 防火墙 | `sudo ufw allow` | `sudo firewall-cmd` |

## 详细文档

完整部署文档请查看：[DEPLOY_ALIBABA_CLOUD_LINUX.md](./DEPLOY_ALIBABA_CLOUD_LINUX.md)

