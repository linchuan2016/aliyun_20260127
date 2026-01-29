# 服务器完整更新指南

> **注意**: 此文档包含详细的更新步骤。快速更新请参考 `README.md` 中的"更新代码"部分。

## 问题诊断

如果网站 https://linchuan.tech/ 显示的是旧版本，需要执行以下完整更新流程：

## 完整更新命令（复制执行）

```bash
# 1. 进入项目目录
cd /var/www/my-fullstack-app

# 2. 检查当前代码版本
echo "=== 当前代码版本 ==="
git log --oneline -1
git status

# 3. 从 Gitee 拉取最新代码
echo "=== 拉取最新代码 ==="
git pull gitee main

# 4. 确认拉取成功
echo "=== 拉取后的版本 ==="
git log --oneline -1

# 5. 激活虚拟环境并更新后端依赖
echo "=== 更新后端依赖 ==="
source venv/bin/activate
cd backend
pip install -r requirements.txt --quiet
cd ..

# 6. 更新数据库（如果需要）
echo "=== 更新数据库 ==="
cd backend
python init_db.py
cd ..

# 7. 清理旧的构建文件
echo "=== 清理旧的前端构建 ==="
cd frontend
rm -rf dist
rm -rf node_modules/.vite

# 8. 重新安装前端依赖（确保最新）
echo "=== 重新安装前端依赖 ==="
npm install --silent

# 9. 重新构建前端（重要！）
echo "=== 重新构建前端 ==="
npm run build

# 10. 检查构建是否成功
echo "=== 检查构建结果 ==="
ls -lh dist/

# 11. 重启后端服务
echo "=== 重启后端服务 ==="
sudo systemctl restart my-fullstack-app

# 12. 重启 Nginx（重要！确保使用新的静态文件）
echo "=== 重启 Nginx ==="
sudo systemctl restart nginx

# 13. 检查服务状态
echo "=== 检查服务状态 ==="
sudo systemctl status my-fullstack-app --no-pager -l | head -15
echo ""
sudo systemctl status nginx --no-pager -l | head -15

# 14. 检查 Nginx 配置的静态文件路径
echo "=== 检查 Nginx 配置 ==="
sudo cat /etc/nginx/conf.d/my-fullstack-app.conf | grep -A 5 "root\|location"

echo ""
echo "=== 更新完成！ ==="
echo "访问地址: https://linchuan.tech"
echo "如果还是旧版本，请清除浏览器缓存（Ctrl+F5）"
```

## 一键执行（单行命令）

```bash
cd /var/www/my-fullstack-app && git pull gitee main && source venv/bin/activate && cd backend && pip install -r requirements.txt --quiet && python init_db.py && cd .. && cd frontend && rm -rf dist node_modules/.vite && npm install --silent && npm run build && cd .. && sudo systemctl restart my-fullstack-app && sudo systemctl restart nginx && echo "更新完成！" && sudo systemctl status my-fullstack-app --no-pager -l | head -10
```

## 常见问题排查

### 1. 如果前端构建失败
```bash
cd /var/www/my-fullstack-app/frontend
rm -rf node_modules
npm install
npm run build
```

### 2. 如果 Nginx 没有加载新文件
```bash
# 检查 Nginx 配置的静态文件路径
sudo cat /etc/nginx/conf.d/my-fullstack-app.conf

# 确认路径指向 frontend/dist
# 如果不对，需要更新配置并重启
sudo systemctl restart nginx
```

### 3. 如果服务启动失败
```bash
# 查看后端日志
sudo journalctl -u my-fullstack-app -n 50 --no-pager

# 查看 Nginx 错误日志
sudo tail -50 /var/log/nginx/error.log
```

### 4. 清除浏览器缓存
- Windows: Ctrl + F5 或 Ctrl + Shift + R
- Mac: Cmd + Shift + R

## 验证更新

更新后访问以下地址验证：
- https://linchuan.tech/ （应该看到导航栏和最新样式）
- https://linchuan.tech/tools （应该看到工具页面）

