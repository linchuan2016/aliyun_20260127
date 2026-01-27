# 在服务器上更新配置

当你从 GitHub 拉取最新代码后，需要在服务器上更新配置文件中的服务器 IP。

## 快速更新命令

在服务器上执行：

```bash
cd /var/www/my-fullstack-app

# 1. 更新服务文件中的服务器 IP
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/systemd/system/my-fullstack-app.service

# 2. 更新 Nginx 配置中的服务器 IP
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/nginx/conf.d/my-fullstack-app.conf

# 3. 重新加载服务
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
sudo systemctl restart nginx

# 4. 验证
sudo systemctl status my-fullstack-app
curl http://localhost:8000/api/data
```

---

## 详细步骤

### 步骤1：拉取最新代码

```bash
cd /var/www/my-fullstack-app
git pull
```

### 步骤2：更新服务文件

```bash
# 复制新的服务文件
sudo cp deploy/my-fullstack-app.service /etc/systemd/system/

# 替换服务器 IP（替换 YOUR_SERVER_IP 为实际 IP）
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/systemd/system/my-fullstack-app.service

# 或者手动编辑
sudo vi /etc/systemd/system/my-fullstack-app.service
# 找到 YOUR_SERVER_IP 并替换为 47.112.29.212
```

### 步骤3：更新 Nginx 配置

```bash
# 复制新的 Nginx 配置
sudo cp deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf

# 替换服务器 IP
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/nginx/conf.d/my-fullstack-app.conf

# 或者手动编辑
sudo vi /etc/nginx/conf.d/my-fullstack-app.conf
# 找到 YOUR_SERVER_IP 并替换为 47.112.29.212
```

### 步骤4：重启服务

```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 重启后端服务
sudo systemctl restart my-fullstack-app

# 测试 Nginx 配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

### 步骤5：验证

```bash
# 检查服务状态
sudo systemctl status my-fullstack-app
sudo systemctl status nginx

# 测试 API
curl http://localhost:8000/api/data
```

---

## 一键更新脚本

创建更新脚本：

```bash
cat > update-config.sh << 'EOF'
#!/bin/bash
SERVER_IP="47.112.29.212"  # 修改为你的服务器 IP

echo "更新服务器配置..."

# 拉取最新代码
cd /var/www/my-fullstack-app
git pull

# 更新服务文件
sudo cp deploy/my-fullstack-app.service /etc/systemd/system/
sudo sed -i "s/YOUR_SERVER_IP/$SERVER_IP/g" /etc/systemd/system/my-fullstack-app.service

# 更新 Nginx 配置
sudo cp deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf
sudo sed -i "s/YOUR_SERVER_IP/$SERVER_IP/g" /etc/nginx/conf.d/my-fullstack-app.conf

# 重启服务
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
sudo nginx -t && sudo systemctl restart nginx

echo "配置更新完成！"
EOF

chmod +x update-config.sh
sudo ./update-config.sh
```

