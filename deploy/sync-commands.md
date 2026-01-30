# 同步代码到阿里云服务器 - 完整命令集

## 方法一：使用健壮版 PowerShell 脚本（推荐）

```powershell
# 在项目根目录执行
.\deploy\sync-to-server-robust.ps1
```

## 方法二：手动执行命令（逐步执行）

### 1. 连接到服务器并处理 Git 冲突

```bash
ssh root@47.112.29.212
cd /var/www/my-fullstack-app

# 如果有本地修改，先保存
git stash push -m "Auto-stash before sync - $(date +%Y%m%d_%H%M%S)"

# 拉取最新代码（强制重置）
git fetch gitee main
git reset --hard gitee/main
```

### 2. 更新后端依赖

```bash
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. 初始化数据库

```bash
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python init_db.py
```

### 4. 构建前端

```bash
cd /var/www/my-fullstack-app/frontend
export NODE_OPTIONS='--max-old-space-size=2048'
npm install
npm run build
```

### 5. 重启服务

```bash
# 重新加载 systemd 配置
systemctl daemon-reload

# 重启后端服务
systemctl restart my-fullstack-app

# 等待几秒
sleep 3

# 重启 Nginx
systemctl restart nginx

# 等待几秒
sleep 2
```

### 6. 检查服务状态

```bash
# 检查后端服务状态
systemctl status my-fullstack-app --no-pager -l

# 检查 Nginx 状态
systemctl status nginx --no-pager -l

# 检查端口监听
netstat -tlnp | grep -E ':(80|8000)'
# 或者
ss -tlnp | grep -E ':(80|8000)'

# 测试 API
curl http://127.0.0.1:8000/api/health
```

## 方法三：一键执行脚本（在服务器上）

```bash
# 将 sync-on-server.sh 上传到服务器后执行
cd /var/www/my-fullstack-app
bash deploy/sync-on-server.sh
```

## 常见问题处理

### 问题 1: Git pull 冲突

```bash
# 方案 A: 保存本地修改
git stash push -m "backup"
git pull gitee main
git stash pop  # 如果需要恢复本地修改

# 方案 B: 强制覆盖（推荐用于生产环境）
git fetch gitee main
git reset --hard gitee/main
```

### 问题 2: 后端服务启动失败

```bash
# 查看详细日志
journalctl -u my-fullstack-app -n 100 --no-pager

# 检查 Python 环境
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python -c "import sys; print(sys.path)"
python -c "from main import app; print('Import OK')"

# 手动测试启动
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000
```

### 问题 3: 前端构建失败

```bash
# 清理 node_modules 重新安装
cd /var/www/my-fullstack-app/frontend
rm -rf node_modules package-lock.json
npm install
npm run build

# 如果内存不足，增加 Node.js 内存限制
export NODE_OPTIONS='--max-old-space-size=2048'
npm run build
```

### 问题 4: Nginx 配置错误

```bash
# 检查 Nginx 配置语法
nginx -t

# 查看 Nginx 错误日志
tail -n 50 /var/log/nginx/my-fullstack-app-error.log

# 重新加载 Nginx（不中断服务）
systemctl reload nginx
```

### 问题 5: 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep 8000
# 或
ss -tlnp | grep 8000

# 杀死占用进程（谨慎使用）
# lsof -ti:8000 | xargs kill -9
```

## 完整诊断命令

```bash
# 在服务器上执行完整诊断
ssh root@47.112.29.212 << 'EOF'
cd /var/www/my-fullstack-app

echo "=== Git 状态 ==="
git status

echo ""
echo "=== 后端服务状态 ==="
systemctl status my-fullstack-app --no-pager -l | head -20

echo ""
echo "=== Nginx 状态 ==="
systemctl status nginx --no-pager -l | head -10

echo ""
echo "=== 端口监听 ==="
netstat -tlnp | grep -E ':(80|8000)' || ss -tlnp | grep -E ':(80|8000)'

echo ""
echo "=== API 健康检查 ==="
curl -s http://127.0.0.1:8000/api/health || echo "API 不可用"

echo ""
echo "=== 后端日志（最近20行）==="
journalctl -u my-fullstack-app -n 20 --no-pager

echo ""
echo "=== Nginx 错误日志（最近20行）==="
tail -n 20 /var/log/nginx/my-fullstack-app-error.log 2>/dev/null || echo "日志文件不存在"
EOF
```

## 快速回滚（如果需要）

```bash
# 回滚到上一个版本
cd /var/www/my-fullstack-app
git log --oneline -5  # 查看提交历史
git reset --hard <commit-hash>  # 回滚到指定提交

# 重启服务
systemctl restart my-fullstack-app
systemctl restart nginx
```

