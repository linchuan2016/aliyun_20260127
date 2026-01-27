# Alibaba Cloud Linux 3.21.04 部署指南

本文档专门针对 **Alibaba Cloud Linux 3.21.04** 的部署说明。

## ⚠️ 重要区别

**Alibaba Cloud Linux 基于 CentOS/RHEL，不是 Ubuntu！**

| 命令类型 | Ubuntu | Alibaba Cloud Linux |
|---------|--------|-------------------|
| **包管理器** | `apt` / `apt-get` | `yum` / `dnf` |
| **更新系统** | `sudo apt update` | `sudo yum update` |
| **安装软件** | `sudo apt install` | `sudo yum install` |
| **其他命令** | ✅ 基本相同 | ✅ 基本相同 |

**注意**：除了包管理器命令不同，其他 Linux 命令（如 `systemctl`、`chmod`、`python3` 等）都是相同的。

---

## 一、服务器环境准备

### 1.1 更新系统

```bash
sudo yum update -y
```

### 1.2 安装必要软件

```bash
# 安装 Python、pip、nginx、git
sudo yum install -y python3 python3-pip nginx git

# 注意：Alibaba Cloud Linux 3 可能没有 python3-venv，需要单独安装
# 如果没有 venv 模块，使用以下命令安装
sudo yum install -y python3-devel
python3 -m pip install --upgrade pip
```

### 1.3 安装 Node.js（用于构建前端）

Alibaba Cloud Linux 使用 `yum`，所以 Node.js 安装方式不同：

```bash
# 方法一：使用 NodeSource（推荐）
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 方法二：使用 Alibaba Cloud 镜像（更快）
# 如果方法一失败，可以尝试：
sudo yum install -y nodejs npm

# 验证安装
node --version
npm --version
```

如果系统自带的 Node.js 版本太低，使用 NodeSource 方法。

---

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
git clone <your-repo-url> /var/www/my-fullstack-app
```
Git 会自动忽略 `venv` 文件夹（已在 `.gitignore` 中配置）。

**方式二：使用 SCP 上传（排除 venv）**
```bash
# 在本地电脑执行（Windows PowerShell）
# 方法1：排除 venv 文件夹
scp -r -x venv D:\Aliyun\my-fullstack-app\* root@your-server-ip:/var/www/my-fullstack-app/

# 方法2：手动排除（推荐，更可靠）
# 在服务器上先创建目录
ssh root@your-server-ip "mkdir -p /var/www/my-fullstack-app"

# 然后分别上传需要的文件夹（排除 venv）
scp -r D:\Aliyun\my-fullstack-app\backend root@your-server-ip:/var/www/my-fullstack-app/
scp -r D:\Aliyun\my-fullstack-app\frontend root@your-server-ip:/var/www/my-fullstack-app/
scp -r D:\Aliyun\my-fullstack-app\deploy root@your-server-ip:/var/www/my-fullstack-app/
scp D:\Aliyun\my-fullstack-app\.gitignore root@your-server-ip:/var/www/my-fullstack-app/ 2>$null
```

### 2.3 设置后端环境

**⚠️ 必须在服务器上创建新的虚拟环境！**

```bash
cd /var/www/my-fullstack-app/backend

# 创建 Python 虚拟环境（在服务器上创建，不要使用本地的 venv）
python3 -m venv ../venv

# 激活虚拟环境
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

---

## 三、配置后端服务（使用 systemd）

### 3.1 创建 systemd 服务文件

```bash
sudo cp /var/www/my-fullstack-app/deploy/my-fullstack-app.service /etc/systemd/system/
```

### 3.2 修改服务文件

编辑服务文件：
```bash
sudo vi /etc/systemd/system/my-fullstack-app.service
```

或使用 nano：
```bash
sudo nano /etc/systemd/system/my-fullstack-app.service
```

修改以下内容：
- `User`: 改为你的用户名（如 `root` 或创建专用用户）
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

---

## 四、配置 Nginx

### 4.1 复制 Nginx 配置

```bash
sudo cp /var/www/my-fullstack-app/deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf
```

**注意**：Alibaba Cloud Linux 的 Nginx 配置通常在 `/etc/nginx/conf.d/` 目录，而不是 `sites-available`。

### 4.2 修改配置

```bash
sudo vi /etc/nginx/conf.d/my-fullstack-app.conf
```

或：
```bash
sudo nano /etc/nginx/conf.d/my-fullstack-app.conf
```

修改以下内容：
- `server_name`: 改为你的域名或服务器 IP
- `root`: 确认前端构建文件路径正确（`/var/www/my-fullstack-app/frontend/dist`）

### 4.3 测试并重启 Nginx

```bash
# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx

# 设置开机自启
sudo systemctl enable nginx

# 查看状态
sudo systemctl status nginx
```

---

## 五、防火墙配置

### 5.1 阿里云安全组配置

在阿里云控制台：
1. 进入轻量应用服务器管理页面
2. 点击你的服务器 → **防火墙** 或 **安全组**
3. 添加规则：
   - 端口：`80`，协议：`TCP`，来源：`0.0.0.0/0`
   - 端口：`443`，协议：`TCP`，来源：`0.0.0.0/0`（如果使用 HTTPS）
   - 端口：`22`，协议：`TCP`，来源：`0.0.0.0/0`（SSH）

### 5.2 服务器防火墙配置（firewalld）

Alibaba Cloud Linux 通常使用 `firewalld`：

```bash
# 检查防火墙状态
sudo systemctl status firewalld

# 如果防火墙未启动，启动它
sudo systemctl start firewalld
sudo systemctl enable firewalld

# 开放端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# 查看开放的端口
sudo firewall-cmd --list-all
```

---

## 六、SSL 证书配置（可选，推荐）

### 6.1 安装 Certbot

```bash
# Alibaba Cloud Linux 使用 yum
sudo yum install -y certbot python3-certbot-nginx
```

### 6.2 获取证书

```bash
sudo certbot --nginx -d your-domain.com -d www.your-domain.com
```

按照提示完成配置，Certbot 会自动修改 Nginx 配置。

---

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

---

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

---

## 九、故障排查

### 9.1 后端无法访问

```bash
# 检查服务是否运行
sudo systemctl status my-fullstack-app

# 检查端口是否监听
sudo netstat -tlnp | grep 8000
# 或使用
sudo ss -tlnp | grep 8000

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
# 或
sudo tail -f /var/log/nginx/error.log
```

### 9.3 Python venv 模块缺失

如果遇到 `python3: No module named venv` 错误：

```bash
# 安装 Python 开发工具
sudo yum install -y python3-devel

# 或者使用 pip 安装
python3 -m pip install virtualenv
python3 -m virtualenv ../venv
```

### 9.4 Node.js 安装失败

如果 NodeSource 安装失败：

```bash
# 尝试使用系统自带的 Node.js
sudo yum install -y nodejs npm

# 或者手动安装 Node.js
# 下载 Node.js 二进制文件
wget https://nodejs.org/dist/v18.x.x/node-v18.x.x-linux-x64.tar.xz
tar -xf node-v18.x.x-linux-x64.tar.xz
sudo mv node-v18.x.x-linux-x64 /opt/nodejs
sudo ln -s /opt/nodejs/bin/node /usr/local/bin/node
sudo ln -s /opt/nodejs/bin/npm /usr/local/bin/npm
```

---

## 十、快速部署命令总结

```bash
# 1. 更新系统
sudo yum update -y

# 2. 安装依赖
sudo yum install -y python3 python3-pip nginx git
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# 3. 上传代码（使用 Git 或 SCP）

# 4. 设置后端
cd /var/www/my-fullstack-app/backend
python3 -m venv ../venv
source ../venv/bin/activate
pip install -r requirements.txt

# 5. 构建前端
cd ../frontend
npm install
npm run build

# 6. 配置服务
sudo cp deploy/my-fullstack-app.service /etc/systemd/system/
sudo cp deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf
# 编辑配置文件，修改域名

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

---

## 注意事项

1. ✅ Alibaba Cloud Linux 使用 `yum` 而不是 `apt`
2. ✅ Nginx 配置文件放在 `/etc/nginx/conf.d/` 而不是 `sites-available`
3. ✅ 防火墙使用 `firewalld` 而不是 `ufw`
4. ✅ 大部分其他 Linux 命令与 Ubuntu 相同
5. ✅ 建议使用域名而非 IP 访问
6. ✅ 强烈建议配置 SSL 证书（HTTPS）

