# 同步代码到阿里云并重启服务

## 快速操作

### 方法1：使用脚本（推荐）

在服务器上执行：

```bash
cd /var/www/my-fullstack-app
chmod +x deploy/sync-and-restart.sh
sudo bash deploy/sync-and-restart.sh
```

---

### 方法2：手动执行

```bash
# 1. 进入项目目录
cd /var/www/my-fullstack-app

# 2. 拉取最新代码（如果 GitHub 可访问）
git pull

# 3. 修复前端代码（如果 GitHub 不可访问，直接修改）
sed -i "s|http://127.0.0.1:8000/api/data|/api/data|g" frontend/src/App.vue

# 4. 重新构建前端
cd frontend
npm run build

# 5. 重启后端服务
sudo systemctl restart my-fullstack-app

# 6. 重启 Nginx
sudo systemctl restart nginx

# 7. 验证
curl http://localhost:8000/api/data
curl http://localhost/api/data
```

---

## 一键命令（复制粘贴）

```bash
cd /var/www/my-fullstack-app && \
git pull 2>/dev/null || echo "GitHub 连接失败，跳过拉取" && \
sed -i "s|http://127.0.0.1:8000/api/data|/api/data|g" frontend/src/App.vue && \
cd frontend && npm run build && \
cd .. && \
sudo systemctl restart my-fullstack-app && \
sudo systemctl restart nginx && \
echo "✓ 同步和重启完成！"
```

---

## 如果 GitHub 连接失败

### 直接修改文件

```bash
# 1. 修改前端文件
vi /var/www/my-fullstack-app/frontend/src/App.vue
```

找到：
```javascript
const response = await fetch('http://127.0.0.1:8000/api/data');
```

改为：
```javascript
const response = await fetch('/api/data');
```

保存退出，然后：

```bash
# 2. 重新构建
cd /var/www/my-fullstack-app/frontend
npm run build

# 3. 重启服务
sudo systemctl restart my-fullstack-app
sudo systemctl restart nginx
```

---

## 验证

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

---

## 常见问题

### 问题1：git pull 失败

**解决：** 直接修改服务器上的文件，参考上面的"直接修改文件"部分

### 问题2：前端构建失败

**解决：**
```bash
cd /var/www/my-fullstack-app/frontend
npm install
npm run build
```

### 问题3：服务重启失败

**解决：**
```bash
# 查看错误日志
sudo journalctl -u my-fullstack-app -n 50
sudo systemctl status nginx
```

