# 后端服务故障排查指南

## 🔍 快速排查步骤

### 步骤1：检查服务状态

```bash
# 查看服务状态
sudo systemctl status my-fullstack-app

# 查看详细错误信息
sudo journalctl -u my-fullstack-app -n 100
```

---

### 步骤2：检查常见问题

#### 问题1：服务文件路径错误

```bash
# 检查服务文件中的路径是否正确
cat /etc/systemd/system/my-fullstack-app.service

# 确认以下路径存在：
ls -la /var/www/my-fullstack-app/backend/main.py
ls -la /var/www/my-fullstack-app/venv/bin/uvicorn
```

#### 问题2：虚拟环境路径错误

```bash
# 检查虚拟环境是否存在
ls -la /var/www/my-fullstack-app/venv/bin/

# 检查 uvicorn 是否存在
ls -la /var/www/my-fullstack-app/venv/bin/uvicorn

# 如果不存在，重新创建虚拟环境
cd /var/www/my-fullstack-app/backend
python3 -m venv ../venv
source ../venv/bin/activate
pip install -r requirements.txt
```

#### 问题3：依赖未安装

```bash
# 激活虚拟环境并检查依赖
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
pip list

# 应该看到 fastapi 和 uvicorn
# 如果没有，重新安装
pip install -r requirements.txt
```

#### 问题4：端口被占用

```bash
# 检查端口 8000 是否被占用
sudo netstat -tlnp | grep 8000
sudo lsof -i :8000

# 如果被占用，可以：
# 1. 停止占用端口的进程
# 2. 或修改服务文件中的端口
```

#### 问题5：权限问题

```bash
# 检查服务文件中的 User 设置
cat /etc/systemd/system/my-fullstack-app.service | grep User

# 如果 User=www-data，但 www-data 用户不存在，改为 root
sudo sed -i 's/User=www-data/User=root/' /etc/systemd/system/my-fullstack-app.service
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

---

## 🔧 修复步骤

### 方法1：重新配置服务（推荐）

```bash
# 1. 停止服务
sudo systemctl stop my-fullstack-app

# 2. 检查并修复服务文件
sudo vi /etc/systemd/system/my-fullstack-app.service
```

**确保服务文件内容正确：**

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

**关键检查点：**
- `User=root`（不是 www-data）
- `WorkingDirectory` 路径正确
- `ExecStart` 中的路径正确
- `Environment PATH` 指向虚拟环境

```bash
# 3. 重新加载并启动
sudo systemctl daemon-reload
sudo systemctl start my-fullstack-app
sudo systemctl status my-fullstack-app
```

---

### 方法2：手动测试运行

```bash
# 1. 进入后端目录
cd /var/www/my-fullstack-app/backend

# 2. 激活虚拟环境
source ../venv/bin/activate

# 3. 检查依赖
pip list | grep -E "fastapi|uvicorn"

# 4. 手动运行（测试）
python main.py
```

**如果手动运行成功：**
- 说明代码和依赖没问题
- 问题在 systemd 服务配置

**如果手动运行失败：**
- 查看错误信息
- 检查依赖是否完整安装

---

### 方法3：重新创建虚拟环境

```bash
# 1. 停止服务
sudo systemctl stop my-fullstack-app

# 2. 删除旧虚拟环境
rm -rf /var/www/my-fullstack-app/venv

# 3. 重新创建虚拟环境
cd /var/www/my-fullstack-app/backend
python3 -m venv ../venv

# 4. 激活并安装依赖
source ../venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 5. 验证安装
pip list

# 6. 测试运行
python main.py
# 按 Ctrl+C 停止

# 7. 重启服务
sudo systemctl start my-fullstack-app
sudo systemctl status my-fullstack-app
```

---

## 📋 完整修复脚本

```bash
#!/bin/bash
# 后端服务修复脚本

echo "开始修复后端服务..."

# 1. 停止服务
echo "[1/6] 停止服务..."
sudo systemctl stop my-fullstack-app

# 2. 检查虚拟环境
echo "[2/6] 检查虚拟环境..."
if [ ! -f "/var/www/my-fullstack-app/venv/bin/uvicorn" ]; then
    echo "虚拟环境不存在或 uvicorn 未安装，重新创建..."
    cd /var/www/my-fullstack-app/backend
    python3 -m venv ../venv
    source ../venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "虚拟环境存在"
fi

# 3. 修复服务文件
echo "[3/6] 修复服务文件..."
sudo sed -i 's/User=www-data/User=root/' /etc/systemd/system/my-fullstack-app.service
sudo sed -i 's|ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=http://47.112.29.212,https://47.112.29.212|' /etc/systemd/system/my-fullstack-app.service

# 4. 重新加载服务
echo "[4/6] 重新加载服务..."
sudo systemctl daemon-reload

# 5. 启动服务
echo "[5/6] 启动服务..."
sudo systemctl start my-fullstack-app
sleep 2

# 6. 检查状态
echo "[6/6] 检查服务状态..."
if systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务启动成功！"
    sudo systemctl status my-fullstack-app --no-pager -l | head -10
else
    echo "✗ 服务启动失败，查看日志："
    sudo journalctl -u my-fullstack-app -n 50
fi
```

---

## 🔍 详细排查命令

### 查看完整错误日志

```bash
# 查看最近100条日志
sudo journalctl -u my-fullstack-app -n 100

# 实时查看日志
sudo journalctl -u my-fullstack-app -f

# 查看所有历史日志
sudo journalctl -u my-fullstack-app --no-pager
```

### 检查文件权限

```bash
# 检查文件权限
ls -la /var/www/my-fullstack-app/backend/main.py
ls -la /var/www/my-fullstack-app/venv/bin/uvicorn

# 如果权限不对，修复
sudo chown -R root:root /var/www/my-fullstack-app
sudo chmod +x /var/www/my-fullstack-app/venv/bin/uvicorn
```

### 检查 Python 版本

```bash
# 检查 Python 版本
python3 --version

# 检查虚拟环境中的 Python
/var/www/my-fullstack-app/venv/bin/python --version
```

---

## 🎯 常见错误及解决方案

### 错误1：`Failed to start my-fullstack-app.service`

**原因：** 服务文件配置错误或路径不存在

**解决：**
```bash
# 检查服务文件
sudo cat /etc/systemd/system/my-fullstack-app.service

# 检查路径是否存在
ls -la /var/www/my-fullstack-app/backend/main.py
ls -la /var/www/my-fullstack-app/venv/bin/uvicorn
```

---

### 错误2：`uvicorn: command not found`

**原因：** 虚拟环境中未安装 uvicorn

**解决：**
```bash
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
pip install uvicorn
```

---

### 错误3：`ModuleNotFoundError: No module named 'fastapi'`

**原因：** 依赖未安装

**解决：**
```bash
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
pip install -r requirements.txt
```

---

### 错误4：`Address already in use`

**原因：** 端口 8000 被占用

**解决：**
```bash
# 查找占用端口的进程
sudo lsof -i :8000

# 停止占用端口的进程（替换 PID）
sudo kill -9 <PID>

# 或修改服务文件使用其他端口
```

---

### 错误5：`Permission denied`

**原因：** 权限不足

**解决：**
```bash
# 修改服务文件中的 User 为 root
sudo sed -i 's/User=www-data/User=root/' /etc/systemd/system/my-fullstack-app.service
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

---

## ✅ 验证修复

修复后，验证服务：

```bash
# 1. 检查服务状态
sudo systemctl status my-fullstack-app

# 2. 检查端口
sudo netstat -tlnp | grep 8000

# 3. 测试 API
curl http://localhost:8000/api/data

# 4. 查看日志
sudo journalctl -u my-fullstack-app -n 20
```

---

## 📞 如果仍然无法解决

请提供以下信息：

1. **服务状态输出：**
   ```bash
   sudo systemctl status my-fullstack-app
   ```

2. **错误日志：**
   ```bash
   sudo journalctl -u my-fullstack-app -n 50
   ```

3. **服务文件内容：**
   ```bash
   cat /etc/systemd/system/my-fullstack-app.service
   ```

4. **手动运行结果：**
   ```bash
   cd /var/www/my-fullstack-app/backend
   source ../venv/bin/activate
   python main.py
   ```

