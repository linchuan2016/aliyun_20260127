# 阿里云轻量级服务器部署指南

本文档介绍如何在阿里云轻量级服务器上部署此全栈应用。

## 前置要求

- 阿里云轻量级服务器（推荐 Ubuntu 20.04/22.04 或 CentOS 7/8）
- 域名（可选，也可以直接使用 IP 访问）
- SSH 访问权限

## 一、服务器环境准备

### 1.1 更新系统

```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y

# CentOS/RHEL
sudo yum update -y
```

### 1.2 安装必要软件

```bash
# Ubuntu/Debian
sudo apt install -y python3 python3-pip python3-venv nginx git

# CentOS/RHEL
sudo yum install -y python3 python3-pip nginx git
```

### 1.3 安装 Node.js（用于构建前端）

```bash
# 使用 NodeSource 安装 Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 验证安装
node --version
npm --version
```

## 二、部署应用

### 2.1 创建应用目录

```bash
sudo mkdir -p /var/www/my-fullstack-app
sudo chown -R $USER:$USER /var/www/my-fullstack-app
cd /var/www/my-fullstack-app
```

### 2.2 上传代码

**⚠️ 重要：不要上传 `venv` 文件夹！**

`venv` 是本地 Python 虚拟环境，包含系统特定的路径，不能跨平台使用（Windows 的 venv 不能在 Linux 上使用）。**必须在服务器上重新创建虚拟环境。**

**方式一：使用 Git（推荐）**
```bash
# 如果代码在 Git 仓库中
git clone <your-repo-url> /var/www/my-fullstack-app
```
Git 会自动忽略 `venv` 文件夹（已在 `.gitignore` 中配置）。

**方式二：使用 SCP 上传（排除 venv）**
```bash
# 在本地电脑执行
# 先创建目录
ssh root@your-server-ip "mkdir -p /var/www/my-fullstack-app"

# 分别上传需要的文件夹（排除 venv、node_modules、dist）
scp -r /path/to/my-fullstack-app/backend root@your-server-ip:/var/www/my-fullstack-app/
scp -r /path/to/my-fullstack-app/frontend root@your-server-ip:/var/www/my-fullstack-app/
scp -r /path/to/my-fullstack-app/deploy root@your-server-ip:/var/www/my-fullstack-app/
```

### 2.3 设置后端环境

**⚠️ 必须在服务器上创建新的虚拟环境！**

```bash
cd /var/www/my-fullstack-app/backend

# 创建 Python 虚拟环境（在服务器上创建，不要使用本地的 venv）
python3 -m venv ../venv
source ../venv/bin/activate

# 升级 pip
pip install --upgrade pip

# 安装依赖（从 requirements.txt 安装）
pip install -r requirements.txt

# 测试运行（可选）
python main.py
# 按 Ctrl+C 停止
```

**为什么要在服务器上创建虚拟环境？**
- Windows 和 Linux 的虚拟环境不兼容
- 虚拟环境包含系统特定的路径和可执行文件
- 服务器上的 Python 版本可能与本地不同
- 重新创建可以确保依赖正确安装

### 2.4 构建前端

```bash
cd /var/www/my-fullstack-app/frontend

# 安装依赖
npm install

# 构建生产版本
# 如果使用域名，设置 API URL
export VITE_API_URL=http://your-domain.com
npm run build

# 构建后的文件在 dist/ 目录
```

## 三、配置后端服务（使用 systemd）

### 3.1 创建 systemd 服务文件

```bash
sudo cp /var/www/my-fullstack-app/deploy/my-fullstack-app.service /etc/systemd/system/
```

### 3.2 修改服务文件

编辑服务文件，修改域名和路径：
```bash
sudo nano /etc/systemd/system/my-fullstack-app.service
```

修改以下内容：
- `User`: 改为你的用户名或 `www-data`
- `WorkingDirectory`: 确认路径正确
- `Environment`: 修改 `ALLOWED_ORIGINS` 为你的域名或 IP
- `ExecStart`: 确认虚拟环境路径正确

### 3.3 启动服务

```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start my-fullstack-app

# 设置开机自启
sudo systemctl enable my-fullstack-app

# 查看状态
sudo systemctl status my-fullstack-app

# 查看日志
sudo journalctl -u my-fullstack-app -f
```

## 四、配置 Nginx

### 4.1 复制 Nginx 配置

```bash
sudo cp /var/www/my-fullstack-app/deploy/nginx.conf /etc/nginx/sites-available/my-fullstack-app
```

### 4.2 修改配置

```bash
sudo nano /etc/nginx/sites-available/my-fullstack-app
```

修改以下内容：
- `server_name`: 改为你的域名或服务器 IP
- `root`: 确认前端构建文件路径正确（应该是 `/var/www/my-fullstack-app/frontend/dist`）

### 4.3 启用站点

```bash
# 创建软链接
sudo ln -s /etc/nginx/sites-available/my-fullstack-app /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx

# 设置开机自启
sudo systemctl enable nginx
```

## 五、防火墙配置

### 5.1 阿里云安全组配置

在阿里云控制台配置安全组规则：
- 开放端口 80（HTTP）
- 开放端口 443（HTTPS，如果使用 SSL）
- 开放端口 22（SSH）

### 5.2 服务器防火墙配置

```bash
# Ubuntu/Debian (UFW)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp
sudo ufw enable

# CentOS/RHEL (firewalld)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

## 六、SSL 证书配置（可选，推荐）

### 6.1 安装 Certbot

```bash
# Ubuntu/Debian
sudo apt install -y certbot python3-certbot-nginx

# CentOS/RHEL
sudo yum install -y certbot python3-certbot-nginx
```

### 6.2 获取证书

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

按照提示完成配置，Certbot 会自动修改 Nginx 配置。

## 七、验证部署

### 7.1 检查后端服务

```bash
# 检查服务状态
sudo systemctl status my-fullstack-app

# 测试 API
curl http://localhost:8000/api/data
curl http://localhost:8000/api/health
```

### 7.2 检查前端

在浏览器访问：
- `http://your-domain.com` 或 `http://your-server-ip`
- 应该能看到 "Lin" 标题和 "Hello World！" 消息

## 八、常用维护命令

### 8.1 后端服务管理

```bash
# 重启服务
sudo systemctl restart my-fullstack-app

# 停止服务
sudo systemctl stop my-fullstack-app

# 查看日志
sudo journalctl -u my-fullstack-app -n 50
sudo journalctl -u my-fullstack-app -f
```

### 8.2 更新代码

```bash
cd /var/www/my-fullstack-app

# 拉取最新代码（如果使用 Git）
git pull

# 更新后端依赖
cd backend
source ../venv/bin/activate
pip install -r requirements.txt

# 重新构建前端
cd ../frontend
npm install
npm run build

# 重启服务
sudo systemctl restart my-fullstack-app
sudo systemctl restart nginx
```

## 九、故障排查

### 9.1 后端无法访问

```bash
# 检查服务是否运行
sudo systemctl status my-fullstack-app

# 检查端口是否监听
sudo netstat -tlnp | grep 8000

# 查看错误日志
sudo journalctl -u my-fullstack-app -n 100
```

### 9.2 前端无法访问

```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 检查 Nginx 配置
sudo nginx -t

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/my-fullstack-app-error.log
```

### 9.3 跨域问题

如果遇到跨域问题，检查：
1. `backend/main.py` 中的 `ALLOWED_ORIGINS` 环境变量
2. systemd 服务文件中的环境变量配置
3. Nginx 配置中的代理设置

## 十、性能优化建议

1. **增加后端工作进程**：在 systemd 服务文件中修改 `--workers` 参数
2. **启用 Gzip 压缩**：在 Nginx 配置中添加 gzip 设置
3. **配置缓存**：前端静态资源已配置缓存
4. **使用 CDN**：将静态资源放到 CDN 加速

## 注意事项

- 生产环境建议使用域名而非 IP
- 强烈建议配置 SSL 证书（HTTPS）
- 定期更新系统和依赖包
- 配置日志轮转，避免日志文件过大
- 设置定期备份


