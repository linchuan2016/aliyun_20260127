# 快速部署指南（阿里云轻量级服务器）

## 快速步骤

### 1. 上传代码到服务器

```bash
# 方式一：使用 Git
git clone <your-repo> /var/www/my-fullstack-app

# 方式二：使用 SCP（在本地执行）
scp -r D:\Aliyun\my-fullstack-app\* root@your-server-ip:/var/www/my-fullstack-app/
```

### 2. 一键部署（推荐）

```bash
cd /var/www/my-fullstack-app
sudo bash deploy/deploy.sh
```

### 3. 手动配置域名

编辑以下文件，将 `your-domain.com` 替换为你的域名或 IP：

```bash
# 修改后端服务配置
sudo nano /etc/systemd/system/my-fullstack-app.service
# 修改 ALLOWED_ORIGINS 环境变量

# 修改 Nginx 配置
sudo nano /etc/nginx/sites-available/my-fullstack-app
# 修改 server_name

# 重启服务
sudo systemctl restart my-fullstack-app
sudo systemctl restart nginx
```

### 4. 配置阿里云安全组

在阿里云控制台 → 轻量应用服务器 → 安全组：
- 开放端口 80（HTTP）
- 开放端口 443（HTTPS，可选）
- 开放端口 22（SSH）

### 5. 访问应用

浏览器访问：`http://your-domain.com` 或 `http://your-server-ip`

## 详细说明

完整部署文档请查看：[DEPLOY.md](./DEPLOY.md)

## 常用命令

```bash
# 查看后端服务状态
sudo systemctl status my-fullstack-app

# 查看后端日志
sudo journalctl -u my-fullstack-app -f

# 重启后端服务
sudo systemctl restart my-fullstack-app

# 重启 Nginx
sudo systemctl restart nginx

# 更新代码后重新部署
cd /var/www/my-fullstack-app
git pull  # 或重新上传代码
cd frontend && npm run build
sudo systemctl restart my-fullstack-app
```


