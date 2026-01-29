# 同步代码到阿里云服务器

## 方法一：使用同步脚本（推荐）

### 前提条件
1. 已配置 SSH 密钥认证（无需密码登录）
2. 服务器已安装 Git

### 执行步骤

```bash
# 给脚本添加执行权限
chmod +x deploy/sync-to-server.sh

# 执行同步脚本
./deploy/sync-to-server.sh
```

---

## 方法二：手动同步（Windows PowerShell）

### 步骤 1: SSH 连接到服务器

```powershell
ssh root@47.112.29.212
```

### 步骤 2: 在服务器上执行以下命令

```bash
# 进入项目目录
cd /var/www/my-fullstack-app

# 检查是否有未提交的更改
git status

# 如果有未提交的更改，先备份
git stash

# 从 Gitee 拉取最新代码
git pull gitee main

# 如果 Gitee 没有配置，可以从 GitHub 拉取
# git pull origin main
```

### 步骤 3: 更新后端依赖

```bash
# 进入后端目录
cd /var/www/my-fullstack-app/backend

# 激活虚拟环境
source /var/www/my-fullstack-app/venv/bin/activate

# 更新依赖
pip install -r requirements.txt

# 初始化/更新数据库
python init_db.py
```

### 步骤 4: 构建前端

```bash
# 进入前端目录
cd /var/www/my-fullstack-app/frontend

# 安装依赖（如果需要）
npm install

# 构建前端
npm run build
```

### 步骤 5: 重启服务

```bash
# 重启后端服务
sudo systemctl restart my-fullstack-app

# 重启 Nginx
sudo systemctl restart nginx

# 检查服务状态
sudo systemctl status my-fullstack-app
sudo systemctl status nginx
```

---

## 方法三：使用 Git 命令直接推送（如果服务器配置了 Git）

如果服务器上已经配置了 Git 远程仓库，可以直接在服务器上拉取：

```bash
ssh root@47.112.29.212 "cd /var/www/my-fullstack-app && git pull gitee main && cd backend && source ../venv/bin/activate && pip install -r requirements.txt && python init_db.py && cd ../frontend && npm run build && systemctl restart my-fullstack-app && systemctl restart nginx"
```

---

## 验证部署

### 1. 检查后端 API

```bash
curl http://47.112.29.212/api/health
curl http://47.112.29.212/api/products
```

### 2. 检查前端页面

浏览器访问：http://47.112.29.212

### 3. 检查服务状态

```bash
ssh root@47.112.29.212 "systemctl status my-fullstack-app"
ssh root@47.112.29.212 "systemctl status nginx"
```

---

## 常见问题

### 问题 1: Git pull 冲突

**解决：**
```bash
cd /var/www/my-fullstack-app
git stash
git pull gitee main
```

### 问题 2: 数据库初始化失败

**解决：**
```bash
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python init_db.py
```

### 问题 3: 前端构建失败

**解决：**
```bash
cd /var/www/my-fullstack-app/frontend
rm -rf node_modules
npm install
npm run build
```

### 问题 4: 服务启动失败

**解决：**
```bash
# 查看服务日志
sudo journalctl -u my-fullstack-app -n 50

# 检查配置文件
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

---

## 注意事项

1. **数据库备份**: 在生产环境更新数据库前，建议先备份
2. **服务重启**: 更新代码后必须重启服务才能生效
3. **依赖更新**: 如果 `requirements.txt` 有变化，需要重新安装依赖
4. **前端构建**: 前端代码更新后必须重新构建并重启 Nginx



