# 修复 Nginx 配置目录问题

## 问题

错误：`cp: cannot create regular file '/etc/nginx/sites-available/my-fullstack-app': No such file or directory`

这是因为阿里云 Linux 可能使用不同的 Nginx 配置目录结构。

---

## 解决方案

### 方法一：使用修复后的脚本（推荐）

```bash
cd /var/www/my-fullstack-app
git pull gitee main
chmod +x deploy/apply-ssl-complete-fixed.sh
sudo ./deploy/apply-ssl-complete-fixed.sh
```

### 方法二：手动检查并配置

#### 步骤 1: 检查 Nginx 配置目录

```bash
# 检查常见的配置目录
ls -la /etc/nginx/
ls -la /etc/nginx/conf.d/
ls -la /etc/nginx/sites-available/ 2>/dev/null || echo "sites-available 不存在"
```

#### 步骤 2: 根据实际情况配置

**如果使用 `/etc/nginx/conf.d/`（阿里云 Linux 常见）：**

```bash
# 复制配置到 conf.d
sudo cp /var/www/my-fullstack-app/deploy/nginx-ssl.conf /etc/nginx/conf.d/my-fullstack-app.conf

# 测试配置
sudo nginx -t

# 重载 Nginx
sudo systemctl reload nginx
```

**如果使用 `/etc/nginx/sites-available/`（Ubuntu/Debian 常见）：**

```bash
# 创建目录（如果不存在）
sudo mkdir -p /etc/nginx/sites-available
sudo mkdir -p /etc/nginx/sites-enabled

# 复制配置
sudo cp /var/www/my-fullstack-app/deploy/nginx-ssl.conf /etc/nginx/sites-available/my-fullstack-app

# 创建软链接
sudo ln -sf /etc/nginx/sites-available/my-fullstack-app /etc/nginx/sites-enabled/my-fullstack-app

# 测试配置
sudo nginx -t

# 重载 Nginx
sudo systemctl reload nginx
```

---

## 完整的手动配置步骤

```bash
# 1. 进入项目目录
cd /var/www/my-fullstack-app

# 2. 拉取最新代码
git pull gitee main

# 3. 检查 Nginx 配置目录
NGINX_CONF_DIR="/etc/nginx/conf.d"
if [ -d "/etc/nginx/sites-available" ]; then
    NGINX_CONF_DIR="/etc/nginx/sites-available"
fi
echo "使用配置目录: $NGINX_CONF_DIR"

# 4. 备份现有配置
sudo cp "$NGINX_CONF_DIR/default.conf" "$NGINX_CONF_DIR/default.conf.backup" 2>/dev/null || true

# 5. 复制 SSL 配置
sudo cp deploy/nginx-ssl.conf "$NGINX_CONF_DIR/my-fullstack-app.conf"

# 6. 测试配置
sudo nginx -t

# 7. 更新 systemd 服务配置
sudo cp deploy/my-fullstack-app-ssl.service /etc/systemd/system/my-fullstack-app.service
sudo systemctl daemon-reload

# 8. 构建前端
cd frontend
npm install
npm run build

# 9. 重启服务
sudo systemctl restart my-fullstack-app
sudo systemctl reload nginx

# 10. 检查状态
sudo systemctl status my-fullstack-app
sudo systemctl status nginx
```

---

## 验证

配置完成后，访问：
- https://linchuan.tech
- https://www.linchuan.tech

应该看到锁图标和正常加载的网站。

