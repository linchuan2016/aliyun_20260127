# 重启应用服务指南

## 快速重启命令

### 在服务器上执行：

```bash
# 重启后端服务
sudo systemctl restart my-fullstack-app

# 重启 Nginx
sudo systemctl restart nginx

# 验证
sudo systemctl status my-fullstack-app
sudo systemctl status nginx
```

---

## 一键重启（复制粘贴）

```bash
sudo systemctl restart my-fullstack-app && \
sudo systemctl restart nginx && \
echo "✓ 服务重启完成！" && \
sleep 2 && \
curl -s http://localhost:8000/api/data && \
curl -s http://localhost/api/data
```

---

## 使用脚本重启

```bash
cd /var/www/my-fullstack-app
chmod +x deploy/restart-services.sh
sudo bash deploy/restart-services.sh
```

---

## 详细操作步骤

### 1. 重启后端服务

```bash
# 停止服务
sudo systemctl stop my-fullstack-app

# 启动服务
sudo systemctl start my-fullstack-app

# 或者直接重启
sudo systemctl restart my-fullstack-app

# 查看状态
sudo systemctl status my-fullstack-app
```

### 2. 重启 Nginx

```bash
# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx

# 查看状态
sudo systemctl status nginx
```

---

## 验证服务

```bash
# 检查服务状态
sudo systemctl status my-fullstack-app
sudo systemctl status nginx

# 测试后端 API
curl http://localhost:8000/api/data

# 测试 Nginx 代理
curl http://localhost/api/data

# 查看日志
sudo journalctl -u my-fullstack-app -n 20
sudo tail -20 /var/log/nginx/error.log
```

---

## 常用服务管理命令

```bash
# 查看服务状态
sudo systemctl status my-fullstack-app
sudo systemctl status nginx

# 启动服务
sudo systemctl start my-fullstack-app
sudo systemctl start nginx

# 停止服务
sudo systemctl stop my-fullstack-app
sudo systemctl stop nginx

# 重启服务
sudo systemctl restart my-fullstack-app
sudo systemctl restart nginx

# 重新加载配置（不中断服务）
sudo systemctl reload nginx

# 查看日志
sudo journalctl -u my-fullstack-app -f
sudo tail -f /var/log/nginx/error.log
```

---

## 如果服务启动失败

```bash
# 查看详细错误
sudo journalctl -u my-fullstack-app -n 50

# 检查配置
cat /etc/systemd/system/my-fullstack-app.service

# 手动测试运行
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python main.py
```

