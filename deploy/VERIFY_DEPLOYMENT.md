# 验证部署是否成功 - 完整检查清单

## ✅ 快速检查（3步）

### 1. 检查服务状态

```bash
# 检查后端服务
sudo systemctl status my-fullstack-app

# 检查 Nginx 服务
sudo systemctl status nginx
```

**成功标志：**
- 显示 `Active: active (running)`
- 没有红色错误信息

---

### 2. 测试后端 API

```bash
# 测试数据接口
curl http://localhost:8000/api/data

# 测试健康检查接口
curl http://localhost:8000/api/health
```

**预期输出：**
```json
{"message":"Hello World！"}
{"status":"ok"}
```

---

### 3. 浏览器访问

在浏览器中打开：`http://47.112.29.212`

**应该看到：**
- 标题："Lin"
- 消息："Hello World！"（绿色文字）

---

## 🔍 详细检查步骤

### 步骤1：检查后端服务

```bash
# 查看服务状态
sudo systemctl status my-fullstack-app

# 查看服务是否正在运行
systemctl is-active my-fullstack-app
# 应该返回：active

# 查看服务是否开机自启
systemctl is-enabled my-fullstack-app
# 应该返回：enabled
```

**如果服务未运行：**
```bash
# 查看错误日志
sudo journalctl -u my-fullstack-app -n 50

# 查看实时日志
sudo journalctl -u my-fullstack-app -f
```

---

### 步骤2：检查后端端口

```bash
# 检查端口 8000 是否在监听
sudo netstat -tlnp | grep 8000
# 或使用
sudo ss -tlnp | grep 8000
```

**预期输出：**
```
tcp    0    0 0.0.0.0:8000    0.0.0.0:*    LISTEN    12345/python
```

**如果端口未监听：**
- 检查服务是否启动
- 查看服务日志

---

### 步骤3：测试后端 API

```bash
# 测试数据接口
curl http://localhost:8000/api/data

# 预期输出：
# {"message":"Hello World！"}

# 测试健康检查
curl http://localhost:8000/api/health

# 预期输出：
# {"status":"ok"}

# 测试 API 文档（FastAPI 自动生成）
curl http://localhost:8000/docs
# 应该返回 HTML 页面
```

**如果 curl 失败：**
```bash
# 检查服务日志
sudo journalctl -u my-fullstack-app -n 100

# 手动测试运行
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python main.py
# 按 Ctrl+C 停止
```

---

### 步骤4：检查 Nginx

```bash
# 查看 Nginx 状态
sudo systemctl status nginx

# 检查 Nginx 配置
sudo nginx -t

# 预期输出：
# nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
# nginx: configuration file /etc/nginx/nginx.conf test is successful

# 检查端口 80 是否在监听
sudo netstat -tlnp | grep 80
# 或
sudo ss -tlnp | grep 80
```

**预期输出：**
```
tcp    0    0 0.0.0.0:80    0.0.0.0:*    LISTEN    12346/nginx
```

---

### 步骤5：检查前端文件

```bash
# 检查前端构建文件是否存在
ls -la /var/www/my-fullstack-app/frontend/dist/

# 应该看到：
# index.html
# assets/ 目录
```

**如果 dist 文件夹不存在：**
```bash
cd /var/www/my-fullstack-app/frontend
npm install
npm run build
```

---

### 步骤6：检查 Nginx 配置

```bash
# 查看 Nginx 配置文件
cat /etc/nginx/conf.d/my-fullstack-app.conf

# 确认以下配置正确：
# - server_name 应该是你的 IP 或域名
# - root 应该指向 /var/www/my-fullstack-app/frontend/dist
# - proxy_pass 应该指向 http://backend (即 127.0.0.1:8000)
```

---

### 步骤7：检查防火墙

```bash
# 检查服务器防火墙
sudo firewall-cmd --list-all

# 应该看到：
# services: http https ssh
```

**如果防火墙未配置：**
```bash
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

**重要：检查阿里云安全组**
1. 登录阿里云控制台
2. 轻量应用服务器 → 你的服务器
3. 防火墙 → 查看规则
4. 确认端口 80 已开放

---

### 步骤8：浏览器测试

#### 8.1 测试前端页面

在浏览器访问：`http://47.112.29.212`

**应该看到：**
- 页面标题："Lin"
- 绿色文字："Hello World！"

**如果看到错误：**
- `502 Bad Gateway` → 后端服务未运行
- `404 Not Found` → 前端文件路径错误
- `无法访问` → 防火墙或安全组未配置

#### 8.2 测试后端 API（通过 Nginx）

在浏览器访问：`http://47.112.29.212/api/data`

**应该看到：**
```json
{"message":"Hello World！"}
```

#### 8.3 测试 API 文档

在浏览器访问：`http://47.112.29.212/docs`

**应该看到：** FastAPI 自动生成的交互式 API 文档

---

### 步骤9：检查日志

```bash
# 后端日志
sudo journalctl -u my-fullstack-app -n 50

# Nginx 访问日志
sudo tail -n 50 /var/log/nginx/my-fullstack-app-access.log

# Nginx 错误日志
sudo tail -n 50 /var/log/nginx/my-fullstack-app-error.log
```

**检查日志中是否有错误信息**

---

## 🎯 一键检查脚本

创建检查脚本：

```bash
cat > check-deployment.sh << 'EOF'
#!/bin/bash
echo "========================================"
echo "  部署验证检查"
echo "========================================"
echo ""

# 1. 检查后端服务
echo "[1/8] 检查后端服务..."
if systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 后端服务运行中"
else
    echo "✗ 后端服务未运行"
fi

# 2. 检查后端端口
echo "[2/8] 检查后端端口..."
if netstat -tlnp | grep -q ":8000"; then
    echo "✓ 端口 8000 正在监听"
else
    echo "✗ 端口 8000 未监听"
fi

# 3. 测试后端 API
echo "[3/8] 测试后端 API..."
if curl -s http://localhost:8000/api/data | grep -q "Hello World"; then
    echo "✓ 后端 API 正常"
else
    echo "✗ 后端 API 异常"
fi

# 4. 检查 Nginx
echo "[4/8] 检查 Nginx..."
if systemctl is-active --quiet nginx; then
    echo "✓ Nginx 运行中"
else
    echo "✗ Nginx 未运行"
fi

# 5. 检查 Nginx 端口
echo "[5/8] 检查 Nginx 端口..."
if netstat -tlnp | grep -q ":80"; then
    echo "✓ 端口 80 正在监听"
else
    echo "✗ 端口 80 未监听"
fi

# 6. 检查前端文件
echo "[6/8] 检查前端文件..."
if [ -f "/var/www/my-fullstack-app/frontend/dist/index.html" ]; then
    echo "✓ 前端文件存在"
else
    echo "✗ 前端文件不存在"
fi

# 7. 检查防火墙
echo "[7/8] 检查防火墙..."
if firewall-cmd --list-all 2>/dev/null | grep -q "http"; then
    echo "✓ 防火墙已配置 HTTP"
else
    echo "⚠️  防火墙未配置 HTTP（请检查阿里云安全组）"
fi

# 8. 测试外部访问
echo "[8/8] 测试外部访问..."
SERVER_IP=$(hostname -I | awk '{print $1}')
if curl -s --max-time 5 "http://$SERVER_IP/api/data" | grep -q "Hello World"; then
    echo "✓ 外部访问正常"
else
    echo "⚠️  外部访问异常（可能是防火墙或安全组问题）"
fi

echo ""
echo "========================================"
echo "  检查完成"
echo "========================================"
echo ""
echo "访问地址: http://47.112.29.212"
echo ""
EOF

chmod +x check-deployment.sh
sudo ./check-deployment.sh
```

---

## ✅ 成功标志总结

如果以下所有项都正常，说明部署成功：

- ✅ 后端服务状态：`active (running)`
- ✅ 后端端口 8000：正在监听
- ✅ 后端 API：返回 `{"message":"Hello World！"}`
- ✅ Nginx 服务状态：`active (running)`
- ✅ Nginx 端口 80：正在监听
- ✅ 前端文件：`dist/index.html` 存在
- ✅ 浏览器访问：显示 "Hello World！"
- ✅ API 访问：`http://47.112.29.212/api/data` 返回 JSON

---

## 🔧 常见问题排查

### 问题1：浏览器显示 502 Bad Gateway

**原因：** 后端服务未运行或端口未监听

**解决：**
```bash
# 检查后端服务
sudo systemctl status my-fullstack-app

# 重启后端服务
sudo systemctl restart my-fullstack-app

# 查看日志
sudo journalctl -u my-fullstack-app -n 50
```

---

### 问题2：浏览器显示 404 Not Found

**原因：** 前端文件路径错误或文件不存在

**解决：**
```bash
# 检查前端文件
ls -la /var/www/my-fullstack-app/frontend/dist/

# 如果不存在，重新构建
cd /var/www/my-fullstack-app/frontend
npm run build

# 检查 Nginx 配置中的 root 路径
cat /etc/nginx/conf.d/my-fullstack-app.conf | grep root
```

---

### 问题3：无法访问网站（连接超时）

**原因：** 防火墙或安全组未配置

**解决：**
1. **检查服务器防火墙：**
   ```bash
   sudo firewall-cmd --list-all
   ```

2. **检查阿里云安全组：**
   - 登录阿里云控制台
   - 轻量应用服务器 → 你的服务器
   - 防火墙 → 添加规则：端口 80，协议 TCP

---

### 问题4：显示 "无法连接到后端！"

**原因：** 前端无法访问后端 API

**解决：**
```bash
# 检查后端是否运行
curl http://localhost:8000/api/data

# 检查 Nginx 代理配置
cat /etc/nginx/conf.d/my-fullstack-app.conf | grep proxy_pass

# 检查 CORS 配置
sudo journalctl -u my-fullstack-app | grep CORS
```

---

## 📊 性能检查

```bash
# 检查服务资源使用
top -p $(pgrep -f "uvicorn main:app")

# 检查 Nginx 连接数
sudo netstat -an | grep :80 | wc -l

# 检查服务响应时间
time curl http://localhost:8000/api/data
```

---

## 🎉 完成！

如果所有检查都通过，恭喜你！部署成功了！

现在可以：
- ✅ 通过浏览器访问：`http://47.112.29.212`
- ✅ 通过 API 访问：`http://47.112.29.212/api/data`
- ✅ 查看 API 文档：`http://47.112.29.212/docs`

