# 解决 Git 冲突并更新前端

## 问题

Git pull 失败，因为本地有未提交的更改会被覆盖。

## 解决方案

### 方法1：暂存本地更改（推荐）

```bash
# 1. 暂存本地更改
cd /var/www/my-fullstack-app
git stash

# 2. 拉取最新代码
git pull gitee main

# 3. 如果需要恢复本地更改（通常不需要）
# git stash pop

# 4. 更新前端
rm -rf frontend/dist
cd frontend
npm run build
cd ..
sudo systemctl restart nginx
```

### 方法2：提交本地更改

```bash
# 1. 提交本地更改
cd /var/www/my-fullstack-app
git add .
git commit -m "local changes"

# 2. 拉取最新代码
git pull gitee main

# 3. 如果有冲突，解决冲突后
git add .
git commit -m "merge conflicts resolved"

# 4. 更新前端
rm -rf frontend/dist
cd frontend
npm run build
cd ..
sudo systemctl restart nginx
```

### 方法3：放弃本地更改（如果不需要保留）

```bash
# 1. 放弃本地更改
cd /var/www/my-fullstack-app
git reset --hard HEAD

# 2. 拉取最新代码
git pull gitee main

# 3. 更新前端
rm -rf frontend/dist
cd frontend
npm run build
cd ..
sudo systemctl restart nginx
```

---

## 一键解决命令（推荐）

```bash
cd /var/www/my-fullstack-app && \
git stash && \
git pull gitee main && \
rm -rf frontend/dist && \
cd frontend && \
npm run build && \
cd .. && \
sudo systemctl restart nginx && \
echo "✓ 更新完成！"
```

---

## 验证

```bash
# 检查源代码
grep "2026.01.28" /var/www/my-fullstack-app/frontend/src/App.vue

# 检查构建文件时间
ls -lth /var/www/my-fullstack-app/frontend/dist/

# 检查构建文件内容
grep -r "2026.01.28" /var/www/my-fullstack-app/frontend/dist/ | head -1
```

