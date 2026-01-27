# 更新代码后的操作指南

## 更新代码后需要做什么？

### 情况1：只更新了前端代码

```bash
# 1. 拉取代码
cd /var/www/my-fullstack-app
git pull

# 2. 重新构建前端
cd frontend
npm run build

# 3. 重启 Nginx（让新构建的前端生效）
sudo systemctl restart nginx
```

### 情况2：只更新了后端代码

```bash
# 1. 拉取代码
cd /var/www/my-fullstack-app
git pull

# 2. 重启后端服务
sudo systemctl restart my-fullstack-app

# 3. 验证
curl http://localhost:8000/api/data
```

### 情况3：更新了配置文件（systemd 或 nginx）

```bash
# 1. 拉取代码
cd /var/www/my-fullstack-app
git pull

# 2. 如果更新了 systemd 服务文件
sudo cp deploy/my-fullstack-app.service /etc/systemd/system/
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/systemd/system/my-fullstack-app.service
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app

# 3. 如果更新了 nginx 配置
sudo cp deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/nginx/conf.d/my-fullstack-app.conf
sudo nginx -t  # 测试配置
sudo systemctl restart nginx
```

### 情况4：完整更新（推荐）

```bash
# 1. 拉取代码
cd /var/www/my-fullstack-app
git pull

# 2. 检查是否有前端代码更新
cd frontend
# 如果有 package.json 变化，重新安装依赖
npm install
# 重新构建前端
npm run build

# 3. 检查是否有后端依赖更新
cd ../backend
source ../venv/bin/activate
pip install -r requirements.txt

# 4. 重启后端服务
sudo systemctl restart my-fullstack-app

# 5. 重启 Nginx
sudo systemctl restart nginx

# 6. 验证
curl http://localhost:8000/api/data
curl http://localhost/api/data
```

## 快速更新命令（一键执行）

```bash
cd /var/www/my-fullstack-app && \
git pull && \
cd frontend && npm run build && \
cd .. && \
sudo systemctl restart my-fullstack-app && \
sudo systemctl restart nginx && \
echo "更新完成！"
```

## 验证更新是否成功

```bash
# 检查服务状态
sudo systemctl status my-fullstack-app
sudo systemctl status nginx

# 测试 API
curl http://localhost:8000/api/data
curl http://localhost/api/data

# 浏览器访问
# http://47.112.29.212
```

