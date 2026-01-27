# 更新前端代码指南

## 问题诊断

如果前端显示的错误消息没有更新，说明服务器上的前端构建文件（`dist/`）还是旧的。

## 快速更新步骤

### 方法1：使用脚本（推荐）

```bash
cd /var/www/my-fullstack-app
chmod +x deploy/update-frontend.sh
sudo bash deploy/update-frontend.sh
```

### 方法2：手动更新

```bash
# 1. 进入项目目录
cd /var/www/my-fullstack-app

# 2. 拉取最新代码
git pull gitee main
# 或
git pull origin main

# 3. 检查源代码是否更新
cat frontend/src/App.vue | grep "无法连接到后端"

# 4. 删除旧的构建文件
rm -rf frontend/dist

# 5. 重新构建前端
cd frontend
npm run build

# 6. 验证构建文件
ls -lth dist/
grep -r "无法连接到后端" dist/ | head -3

# 7. 重启 Nginx
sudo systemctl restart nginx
```

---

## 一键更新命令（复制粘贴）

```bash
cd /var/www/my-fullstack-app && \
git pull gitee main 2>/dev/null || git pull origin main 2>/dev/null || echo "Git 拉取失败" && \
rm -rf frontend/dist && \
cd frontend && \
npm run build && \
cd .. && \
sudo systemctl restart nginx && \
echo "✓ 前端更新完成！" && \
echo "构建文件时间：" && \
ls -lth frontend/dist/ | head -3
```

---

## 验证更新是否成功

### 1. 检查源代码

```bash
# 查看 App.vue 中的错误消息
grep "无法连接到后端" /var/www/my-fullstack-app/frontend/src/App.vue
```

应该看到：`无法连接到后端!2026.01.28` 或 `无法连接到后端！2026.01.28`

### 2. 检查构建文件

```bash
# 查看构建后的 JS 文件中的错误消息
grep -r "无法连接到后端" /var/www/my-fullstack-app/frontend/dist/ | head -3
```

应该能看到包含日期的新消息。

### 3. 检查构建文件时间

```bash
ls -lth /var/www/my-fullstack-app/frontend/dist/
```

文件时间应该是刚刚构建的（最新的）。

### 4. 浏览器测试

1. **清除浏览器缓存**：
   - Chrome: Ctrl+Shift+Delete
   - 或使用无痕模式：Ctrl+Shift+N

2. **强制刷新**：
   - Ctrl+F5（Windows）
   - Cmd+Shift+R（Mac）

3. **访问**：`http://47.112.29.212`

4. **打开开发者工具**（F12）→ Network 标签
   - 查看请求的 JS 文件时间
   - 确认加载的是新文件

---

## 如果还是不行

### 检查 Nginx 配置

```bash
# 确认 Nginx 指向正确的目录
cat /etc/nginx/conf.d/my-fullstack-app.conf | grep root

# 应该看到：
# root /var/www/my-fullstack-app/frontend/dist;
```

### 检查文件权限

```bash
# 确保 Nginx 可以读取文件
ls -la /var/www/my-fullstack-app/frontend/dist/
sudo chown -R nginx:nginx /var/www/my-fullstack-app/frontend/dist/
```

### 查看 Nginx 日志

```bash
# 查看错误日志
sudo tail -f /var/log/nginx/error.log

# 查看访问日志
sudo tail -f /var/log/nginx/my-fullstack-app-access.log
```

---

## 常见问题

### 问题1：构建后还是旧内容

**原因：** 可能构建时使用了缓存

**解决：**
```bash
cd /var/www/my-fullstack-app/frontend
rm -rf dist node_modules/.vite
npm run build
```

### 问题2：浏览器缓存

**解决：**
- 清除浏览器缓存
- 使用无痕模式
- 强制刷新（Ctrl+F5）

### 问题3：Nginx 缓存

**解决：**
```bash
# 重启 Nginx
sudo systemctl restart nginx

# 或重新加载配置
sudo nginx -s reload
```

---

## 完整更新流程

```bash
# 1. 拉取代码
cd /var/www/my-fullstack-app
git pull gitee main

# 2. 确认源代码已更新
cat frontend/src/App.vue | grep "2026.01.28"

# 3. 清理并重新构建
cd frontend
rm -rf dist node_modules/.vite
npm run build

# 4. 验证构建文件
grep -r "2026.01.28" dist/ && echo "✓ 构建文件包含新消息"

# 5. 重启 Nginx
sudo systemctl restart nginx

# 6. 测试
curl http://localhost/api/data
```

