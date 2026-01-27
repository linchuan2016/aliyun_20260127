# 完整排查和修复指南

## 🔍 第一步：检查后端服务状态

在服务器上执行：

```bash
# 1. 检查服务是否运行
sudo systemctl status my-fullstack-app

# 2. 如果未运行，查看错误日志
sudo journalctl -u my-fullstack-app -n 50

# 3. 检查端口是否监听
sudo netstat -tlnp | grep 8000
# 或
sudo ss -tlnp | grep 8000

# 4. 测试后端 API（本地测试）
curl http://localhost:8000/api/data
```

---

## 🔧 第二步：如果服务未运行，修复它

### 方法1：检查并修复服务文件

```bash
# 1. 查看服务文件内容
cat /etc/systemd/system/my-fullstack-app.service

# 2. 检查关键路径是否存在
ls -la /var/www/my-fullstack-app/backend/main.py
ls -la /var/www/my-fullstack-app/venv/bin/uvicorn

# 3. 如果 uvicorn 不存在，重新安装依赖
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
pip install -r requirements.txt

# 4. 修复服务文件中的 IP（如果还是 YOUR_SERVER_IP）
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/systemd/system/my-fullstack-app.service

# 5. 确保 User 是 root
sudo sed -i 's/User=www-data/User=root/' /etc/systemd/system/my-fullstack-app.service

# 6. 重新加载并启动
sudo systemctl daemon-reload
sudo systemctl start my-fullstack-app
sudo systemctl status my-fullstack-app
```

### 方法2：手动测试运行

```bash
# 1. 进入后端目录
cd /var/www/my-fullstack-app/backend

# 2. 激活虚拟环境
source ../venv/bin/activate

# 3. 手动运行（测试是否能正常启动）
python main.py
```

**如果手动运行成功：**
- 说明代码没问题，问题在服务配置
- 按 Ctrl+C 停止，然后修复服务文件

**如果手动运行失败：**
- 查看错误信息
- 可能是依赖未安装或代码有问题

---

## 🌐 第三步：检查 Nginx 配置

```bash
# 1. 检查 Nginx 是否运行
sudo systemctl status nginx

# 2. 检查 Nginx 配置
sudo nginx -t

# 3. 查看 Nginx 配置文件
cat /etc/nginx/conf.d/my-fullstack-app.conf

# 4. 检查前端文件是否存在
ls -la /var/www/my-fullstack-app/frontend/dist/

# 5. 如果前端文件不存在，重新构建
cd /var/www/my-fullstack-app/frontend
npm install
npm run build

# 6. 查看 Nginx 错误日志
sudo tail -f /var/log/nginx/my-fullstack-app-error.log
# 或
sudo tail -f /var/log/nginx/error.log
```

---

## 🔄 第四步：完整重启流程

```bash
# 1. 停止所有服务
sudo systemctl stop my-fullstack-app
sudo systemctl stop nginx

# 2. 检查并修复服务文件
sudo vi /etc/systemd/system/my-fullstack-app.service
# 确保：
# - User=root
# - ALLOWED_ORIGINS=http://47.112.29.212,https://47.112.29.212
# - 路径都正确

# 3. 检查并修复 Nginx 配置
sudo vi /etc/nginx/conf.d/my-fullstack-app.conf
# 确保：
# - server_name 47.112.29.212;
# - root /var/www/my-fullstack-app/frontend/dist;

# 4. 重新加载配置
sudo systemctl daemon-reload
sudo nginx -t

# 5. 启动服务
sudo systemctl start my-fullstack-app
sudo systemctl start nginx

# 6. 检查状态
sudo systemctl status my-fullstack-app
sudo systemctl status nginx

# 7. 测试
curl http://localhost:8000/api/data
curl http://localhost/api/data
```

---

## 🐛 第五步：查看详细错误

### 后端错误

```bash
# 查看完整日志
sudo journalctl -u my-fullstack-app --no-pager

# 实时查看日志
sudo journalctl -u my-fullstack-app -f

# 查看最近的错误
sudo journalctl -u my-fullstack-app -n 100 | grep -i error
```

### Nginx 错误

```bash
# 查看错误日志
sudo tail -50 /var/log/nginx/error.log
sudo tail -50 /var/log/nginx/my-fullstack-app-error.log

# 查看访问日志
sudo tail -50 /var/log/nginx/my-fullstack-app-access.log
```

---

## ✅ 第六步：验证修复

```bash
# 1. 检查后端服务
sudo systemctl status my-fullstack-app | grep Active

# 2. 检查后端端口
sudo netstat -tlnp | grep 8000

# 3. 测试后端 API（本地）
curl http://localhost:8000/api/data

# 4. 检查 Nginx
sudo systemctl status nginx | grep Active

# 5. 检查 Nginx 端口
sudo netstat -tlnp | grep 80

# 6. 测试 Nginx 代理的 API
curl http://localhost/api/data

# 7. 测试外部访问（从服务器内部）
curl http://47.112.29.212/api/data
```

---

## 🚀 一键修复脚本

```bash
cat > complete-fix.sh << 'EOF'
#!/bin/bash
set -e

echo "开始完整修复..."

# 1. 检查虚拟环境
cd /var/www/my-fullstack-app/backend
if [ ! -f "../venv/bin/uvicorn" ]; then
    echo "重新创建虚拟环境..."
    python3 -m venv ../venv
    source ../venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# 2. 修复服务文件
echo "修复服务文件..."
sudo cp /var/www/my-fullstack-app/deploy/my-fullstack-app.service /etc/systemd/system/
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/systemd/system/my-fullstack-app.service
sudo sed -i 's/User=www-data/User=root/' /etc/systemd/system/my-fullstack-app.service

# 3. 修复 Nginx 配置
echo "修复 Nginx 配置..."
sudo cp /var/www/my-fullstack-app/deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/nginx/conf.d/my-fullstack-app.conf

# 4. 构建前端（如果需要）
if [ ! -d "/var/www/my-fullstack-app/frontend/dist" ]; then
    echo "构建前端..."
    cd /var/www/my-fullstack-app/frontend
    npm install
    npm run build
fi

# 5. 重新加载并启动
echo "启动服务..."
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
sleep 2
sudo nginx -t && sudo systemctl restart nginx

# 6. 验证
echo ""
echo "验证服务状态..."
sleep 2
if systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 后端服务运行中"
else
    echo "✗ 后端服务未运行"
    sudo journalctl -u my-fullstack-app -n 20
fi

if systemctl is-active --quiet nginx; then
    echo "✓ Nginx 运行中"
else
    echo "✗ Nginx 未运行"
fi

echo ""
echo "测试 API:"
curl -s http://localhost:8000/api/data || echo "后端 API 失败"
curl -s http://localhost/api/data || echo "Nginx 代理失败"
EOF

chmod +x complete-fix.sh
sudo ./complete-fix.sh
```

---

## 📋 请提供以下信息

如果还是不行，请执行以下命令并提供输出：

```bash
# 1. 服务状态
sudo systemctl status my-fullstack-app

# 2. 后端日志
sudo journalctl -u my-fullstack-app -n 50

# 3. 端口监听
sudo netstat -tlnp | grep 8000

# 4. 手动运行测试
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python main.py
# 运行几秒后按 Ctrl+C，告诉我看到了什么

# 5. Nginx 状态
sudo systemctl status nginx
sudo nginx -t

# 6. Nginx 日志
sudo tail -20 /var/log/nginx/error.log
```

把这些信息发给我，我可以帮你精确定位问题！

