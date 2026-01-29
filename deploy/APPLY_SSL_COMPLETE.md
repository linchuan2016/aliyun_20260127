# 应用 SSL 配置 - 完整步骤

证书已上传，现在需要应用 SSL 配置并重启服务。

---

## 步骤 1: 同步代码到服务器

确保最新的 SSL 配置文件在服务器上：

```bash
# SSH 连接到服务器
ssh root@47.112.29.212

# 进入项目目录
cd /var/www/my-fullstack-app

# 拉取最新代码
git pull gitee main
# 或
git pull origin main
```

---

## 步骤 2: 应用 SSL 配置

### 方法一：使用一键脚本（推荐）

```bash
cd /var/www/my-fullstack-app
chmod +x deploy/apply-ssl-complete.sh
sudo ./deploy/apply-ssl-complete.sh
```

### 方法二：手动执行

#### 2.1 备份现有配置

```bash
sudo cp /etc/nginx/sites-available/my-fullstack-app /etc/nginx/sites-available/my-fullstack-app.backup
sudo cp /etc/systemd/system/my-fullstack-app.service /etc/systemd/system/my-fullstack-app.service.backup
```

#### 2.2 应用 Nginx SSL 配置

```bash
cd /var/www/my-fullstack-app
sudo cp deploy/nginx-ssl.conf /etc/nginx/sites-available/my-fullstack-app

# 测试配置
sudo nginx -t
```

#### 2.3 更新 systemd 服务配置

```bash
sudo cp deploy/my-fullstack-app-ssl.service /etc/systemd/system/my-fullstack-app.service
sudo systemctl daemon-reload
```

#### 2.4 构建前端

```bash
cd /var/www/my-fullstack-app/frontend
npm install
npm run build
```

#### 2.5 重启服务

```bash
sudo systemctl restart my-fullstack-app
sudo systemctl reload nginx
```

---

## 步骤 3: 验证部署

### 3.1 检查服务状态

```bash
# 检查后端服务
sudo systemctl status my-fullstack-app

# 检查 Nginx
sudo systemctl status nginx
```

### 3.2 测试 HTTPS 访问

在浏览器访问：
- ✅ https://linchuan.tech
- ✅ https://www.linchuan.tech

应该看到：
- 🔒 浏览器地址栏显示锁图标
- ✅ 网站正常加载
- ✅ 产品列表正常显示

### 3.3 测试 HTTP 重定向

访问：
- http://linchuan.tech

应该自动重定向到：
- https://linchuan.tech

### 3.4 测试 API

```bash
# 测试健康检查
curl https://linchuan.tech/api/health

# 测试产品 API
curl https://linchuan.tech/api/products
```

---

## 故障排查

### 问题 1: Nginx 启动失败

```bash
# 查看错误日志
sudo tail -50 /var/log/nginx/error.log

# 检查证书文件
sudo ls -la /etc/nginx/ssl/linchuan.tech/

# 检查证书文件权限
sudo chmod 600 /etc/nginx/ssl/linchuan.tech/*
```

### 问题 2: 后端服务未运行

```bash
# 查看服务日志
sudo journalctl -u my-fullstack-app -n 50

# 检查服务状态
sudo systemctl status my-fullstack-app
```

### 问题 3: SSL 证书错误

- ✅ 确认证书文件路径正确
- ✅ 确认证书文件内容完整
- ✅ 确认域名解析正确（`linchuan.tech` → `47.112.29.212`）

### 问题 4: CORS 错误

检查后端日志：
```bash
sudo journalctl -u my-fullstack-app -f
```

确认 `ALLOWED_ORIGINS` 环境变量包含 `https://linchuan.tech`

---

## 完成！

部署完成后，你的网站将通过 HTTPS 安全访问：
- 🌐 https://linchuan.tech
- 🔒 自动 HTTP 到 HTTPS 重定向
- ✅ 安全的 API 通信

如有问题，请查看日志或联系技术支持。

