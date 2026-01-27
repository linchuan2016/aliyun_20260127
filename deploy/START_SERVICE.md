# 启动服务 - 完整步骤

假设你已经完成了：
- ✅ 代码已克隆到服务器
- ✅ 虚拟环境已创建
- ✅ 后端依赖已安装
- ✅ 前端已构建

---

## 第一步：确认前端已构建

```bash
# 进入前端目录
cd /var/www/my-fullstack-app/frontend

# 检查 dist 文件夹是否存在
ls -la dist/

# 如果不存在，需要先构建
npm install
npm run build
```

---

## 第二步：配置后端服务（systemd）

### 2.1 复制服务文件

```bash
sudo cp /var/www/my-fullstack-app/deploy/my-fullstack-app.service /etc/systemd/system/
```

### 2.2 修改服务配置

```bash
sudo vi /etc/systemd/system/my-fullstack-app.service
```

**需要修改的内容：**

1. **User**（第7行）：改为 `root` 或你的用户名
   ```ini
   User=root
   ```

2. **ALLOWED_ORIGINS**（第12行）：改为你的服务器 IP 或域名
   ```ini
   Environment="ALLOWED_ORIGINS=http://47.112.29.212,https://47.112.29.212"
   ```

**完整示例：**
```ini
[Unit]
Description=My Fullstack App Backend Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/my-fullstack-app/backend
Environment="PATH=/var/www/my-fullstack-app/venv/bin"
Environment="HOST=0.0.0.0"
Environment="PORT=8000"
Environment="ALLOWED_ORIGINS=http://47.112.29.212,https://47.112.29.212"
ExecStart=/var/www/my-fullstack-app/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**保存退出：**
- `vi` 编辑器：按 `Esc`，输入 `:wq`，按回车
- `nano` 编辑器：按 `Ctrl+X`，输入 `Y`，按回车

### 2.3 启动后端服务

```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start my-fullstack-app

# 设置开机自启
sudo systemctl enable my-fullstack-app

# 查看状态
sudo systemctl status my-fullstack-app
```

**如果状态显示 `active (running)`，说明启动成功！**

### 2.4 查看后端日志

```bash
# 查看实时日志
sudo journalctl -u my-fullstack-app -f

# 查看最近50条日志
sudo journalctl -u my-fullstack-app -n 50
```

---

## 第三步：配置 Nginx

### 3.1 安装 Nginx（如果未安装）

```bash
sudo yum install -y nginx
```

### 3.2 复制 Nginx 配置

```bash
sudo cp /var/www/my-fullstack-app/deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf
```

### 3.3 修改 Nginx 配置

```bash
sudo vi /etc/nginx/conf.d/my-fullstack-app.conf
```

**需要修改：**

1. **server_name**（第12行）：改为你的服务器 IP
   ```nginx
   server_name 47.112.29.212;
   ```

2. **确认 root 路径**（第15行）：确保指向前端构建目录
   ```nginx
   root /var/www/my-fullstack-app/frontend/dist;
   ```

**保存退出**

### 3.4 测试并启动 Nginx

```bash
# 测试配置是否正确
sudo nginx -t

# 如果显示 "syntax is ok" 和 "test is successful"，说明配置正确

# 启动 Nginx
sudo systemctl start nginx

# 设置开机自启
sudo systemctl enable nginx

# 查看状态
sudo systemctl status nginx
```

---

## 第四步：配置防火墙

### 4.1 服务器防火墙

```bash
# 检查防火墙状态
sudo systemctl status firewalld

# 开放 HTTP 端口
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# 查看开放的端口
sudo firewall-cmd --list-all
```

### 4.2 阿里云安全组（重要！）

**在阿里云控制台配置：**

1. 登录阿里云控制台
2. 进入 **轻量应用服务器** → 你的服务器
3. 点击 **防火墙** 或 **安全组**
4. 添加规则：
   - **端口**：`80`
   - **协议**：`TCP`
   - **来源**：`0.0.0.0/0`
   - 点击 **保存**

---

## 第五步：验证服务

### 5.1 检查后端服务

```bash
# 检查服务状态
sudo systemctl status my-fullstack-app

# 测试后端 API
curl http://localhost:8000/api/data
curl http://localhost:8000/api/health
```

**预期输出：**
```json
{"message":"Hello World！"}
{"status":"ok"}
```

### 5.2 检查 Nginx

```bash
# 检查 Nginx 状态
sudo systemctl status nginx

# 测试 Nginx 配置
sudo nginx -t
```

### 5.3 浏览器访问

在浏览器中访问：`http://47.112.29.212`

**应该能看到：**
- 标题："Lin"
- 消息："Hello World！"

---

## 常用管理命令

### 重启服务

```bash
# 重启后端
sudo systemctl restart my-fullstack-app

# 重启 Nginx
sudo systemctl restart nginx

# 同时重启
sudo systemctl restart my-fullstack-app && sudo systemctl restart nginx
```

### 停止服务

```bash
# 停止后端
sudo systemctl stop my-fullstack-app

# 停止 Nginx
sudo systemctl stop nginx
```

### 查看日志

```bash
# 后端日志
sudo journalctl -u my-fullstack-app -f

# Nginx 错误日志
sudo tail -f /var/log/nginx/my-fullstack-app-error.log

# Nginx 访问日志
sudo tail -f /var/log/nginx/my-fullstack-app-access.log
```

---

## 故障排查

### 问题1：后端服务启动失败

```bash
# 查看详细错误
sudo journalctl -u my-fullstack-app -n 100

# 检查虚拟环境路径是否正确
ls -la /var/www/my-fullstack-app/venv/bin/uvicorn

# 手动测试运行
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python main.py
```

### 问题2：Nginx 502 Bad Gateway

```bash
# 检查后端是否运行
sudo systemctl status my-fullstack-app

# 检查端口是否监听
sudo netstat -tlnp | grep 8000

# 检查 Nginx 错误日志
sudo tail -f /var/log/nginx/error.log
```

### 问题3：无法访问网站

1. **检查防火墙**：
   ```bash
   sudo firewall-cmd --list-all
   ```

2. **检查阿里云安全组**：确保端口 80 已开放

3. **检查服务状态**：
   ```bash
   sudo systemctl status my-fullstack-app
   sudo systemctl status nginx
   ```

---

## 快速启动命令总结

```bash
# 1. 配置后端服务
sudo cp /var/www/my-fullstack-app/deploy/my-fullstack-app.service /etc/systemd/system/
sudo vi /etc/systemd/system/my-fullstack-app.service  # 修改 User 和 ALLOWED_ORIGINS
sudo systemctl daemon-reload
sudo systemctl enable my-fullstack-app
sudo systemctl start my-fullstack-app

# 2. 配置 Nginx
sudo cp /var/www/my-fullstack-app/deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf
sudo vi /etc/nginx/conf.d/my-fullstack-app.conf  # 修改 server_name
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl start nginx

# 3. 配置防火墙
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --reload

# 4. 验证
curl http://localhost:8000/api/data
```

---

## 完成！

如果一切正常，你现在应该可以通过浏览器访问：`http://47.112.29.212`

看到 "Hello World！" 就说明部署成功了！🎉

