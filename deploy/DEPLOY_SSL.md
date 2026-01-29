# SSL 证书部署指南 - linchuan.tech

本指南将帮助你在阿里云服务器上部署 SSL 证书，启用 HTTPS 访问。

---

## 📋 前置要求

- ✅ 已获得阿里云 DV SSL 证书
- ✅ 域名 `linchuan.tech` 已解析到服务器 IP `47.112.29.212`
- ✅ 服务器已安装 Nginx
- ✅ 已 SSH 连接到服务器

---

## 📦 步骤 1: 上传 SSL 证书到服务器

### 方法一：使用 SCP 上传（推荐）

**在本地 Windows PowerShell 执行：**

```powershell
# 假设你的证书文件在本地路径
# 证书文件通常包括：
# - 证书文件（.pem 或 .crt）
# - 私钥文件（.key）

# 创建 SSL 证书目录
ssh root@47.112.29.212 "mkdir -p /etc/nginx/ssl/linchuan.tech"

# 上传证书文件（请替换为你的实际证书文件路径）
scp "你的证书文件.pem" root@47.112.29.212:/etc/nginx/ssl/linchuan.tech/fullchain.pem
scp "你的私钥文件.key" root@47.112.29.212:/etc/nginx/ssl/linchuan.tech/privkey.pem
```

### 方法二：在服务器上直接创建

**SSH 连接到服务器后：**

```bash
# 创建证书目录
sudo mkdir -p /etc/nginx/ssl/linchuan.tech

# 设置目录权限
sudo chmod 700 /etc/nginx/ssl/linchuan.tech

# 创建证书文件（使用 vi 或 nano 编辑器）
sudo vi /etc/nginx/ssl/linchuan.tech/fullchain.pem
# 粘贴证书内容（包括中间证书）

sudo vi /etc/nginx/ssl/linchuan.tech/privkey.pem
# 粘贴私钥内容

# 设置文件权限
sudo chmod 600 /etc/nginx/ssl/linchuan.tech/fullchain.pem
sudo chmod 600 /etc/nginx/ssl/linchuan.tech/privkey.pem
```

---

## 🔧 步骤 2: 配置 Nginx

### 2.1 上传新的 Nginx 配置

**在本地执行：**

```powershell
# 同步配置文件到服务器
scp deploy/nginx-ssl.conf root@47.112.29.212:/tmp/nginx-ssl.conf
```

**在服务器上执行：**

```bash
# 备份现有配置
sudo cp /etc/nginx/sites-available/my-fullstack-app /etc/nginx/sites-available/my-fullstack-app.backup

# 复制新配置
sudo cp /tmp/nginx-ssl.conf /etc/nginx/sites-available/my-fullstack-app

# 或者直接编辑配置文件
sudo vi /etc/nginx/sites-available/my-fullstack-app
```

### 2.2 验证 Nginx 配置

```bash
# 测试配置文件语法
sudo nginx -t

# 如果显示 "syntax is ok" 和 "test is successful"，说明配置正确
```

### 2.3 重载 Nginx

```bash
sudo systemctl reload nginx
# 或
sudo systemctl restart nginx
```

---

## 🔄 步骤 3: 更新后端 CORS 配置

### 3.1 更新 systemd 服务配置

**在本地执行：**

```powershell
scp deploy/my-fullstack-app-ssl.service root@47.112.29.212:/tmp/my-fullstack-app-ssl.service
```

**在服务器上执行：**

```bash
# 备份现有服务配置
sudo cp /etc/systemd/system/my-fullstack-app.service /etc/systemd/system/my-fullstack-app.service.backup

# 复制新配置
sudo cp /tmp/my-fullstack-app-ssl.service /etc/systemd/system/my-fullstack-app.service

# 重新加载 systemd
sudo systemctl daemon-reload

# 重启后端服务
sudo systemctl restart my-fullstack-app

# 检查服务状态
sudo systemctl status my-fullstack-app
```

---

## 🌐 步骤 4: 更新域名解析

确保域名已正确解析到服务器 IP：

```bash
# 检查域名解析
nslookup linchuan.tech
# 或
dig linchuan.tech

# 应该返回: 47.112.29.212
```

**如果域名未解析，请在域名管理后台添加 A 记录：**
- 主机记录：`@` 或 `linchuan.tech`
- 记录类型：`A`
- 记录值：`47.112.29.212`
- TTL：`600`（或默认值）

---

## ✅ 步骤 5: 验证部署

### 5.1 检查 HTTPS 访问

在浏览器访问：
- ✅ https://linchuan.tech
- ✅ https://www.linchuan.tech

应该看到：
- 🔒 浏览器地址栏显示锁图标
- ✅ 网站正常加载
- ✅ 产品列表正常显示

### 5.2 检查 HTTP 重定向

访问：
- http://linchuan.tech

应该自动重定向到：
- https://linchuan.tech

### 5.3 检查 SSL 证书

```bash
# 使用 openssl 检查证书
openssl s_client -connect linchuan.tech:443 -servername linchuan.tech

# 或使用 curl
curl -I https://linchuan.tech
```

### 5.4 检查后端 API

```bash
# 测试 API 端点
curl https://linchuan.tech/api/health
curl https://linchuan.tech/api/products
```

---

## 🔍 故障排查

### 问题 1: Nginx 启动失败

```bash
# 查看错误日志
sudo tail -50 /var/log/nginx/error.log

# 检查证书文件路径是否正确
sudo ls -la /etc/nginx/ssl/linchuan.tech/

# 检查证书文件权限
sudo chmod 600 /etc/nginx/ssl/linchuan.tech/*
```

### 问题 2: SSL 证书错误

- ✅ 确认证书文件路径正确
- ✅ 确认证书文件内容完整（包括中间证书）
- ✅ 确认私钥文件正确
- ✅ 确认证书未过期

### 问题 3: CORS 错误

检查后端日志：
```bash
sudo journalctl -u my-fullstack-app -f
```

确认 `ALLOWED_ORIGINS` 环境变量包含 `https://linchuan.tech`

### 问题 4: 域名无法访问

```bash
# 检查防火墙
sudo firewall-cmd --list-all
# 或
sudo iptables -L

# 确保 80 和 443 端口开放
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

---

## 📝 证书文件说明

阿里云 DV SSL 证书通常包含以下文件：

1. **证书文件** (`*.pem` 或 `*.crt`)
   - 包含域名证书和中间证书
   - 上传为 `fullchain.pem`

2. **私钥文件** (`*.key`)
   - 证书的私钥
   - 上传为 `privkey.pem`

**注意：** 如果阿里云提供的是 `.pem` 和 `.key` 文件，直接使用即可。如果是其他格式，可能需要转换。

---

## 🔄 证书更新

SSL 证书通常有效期为 1 年。到期前需要更新：

1. 在阿里云控制台申请新证书
2. 下载新证书文件
3. 按照步骤 1 上传新证书
4. 重载 Nginx：`sudo systemctl reload nginx`

---

## 📚 相关文件

- `deploy/nginx-ssl.conf` - Nginx SSL 配置文件
- `deploy/my-fullstack-app-ssl.service` - 更新后的 systemd 服务配置

---

## ✨ 完成！

部署完成后，你的网站将通过 HTTPS 安全访问：
- 🌐 https://linchuan.tech
- 🔒 自动 HTTP 到 HTTPS 重定向
- ✅ 安全的 API 通信

如有问题，请查看日志或联系技术支持。

