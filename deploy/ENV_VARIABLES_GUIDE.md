# 环境变量配置指南

## 📍 环境变量在哪里配置？

**环境变量是在服务器上的 systemd 服务文件中配置的，不是在阿里云控制台！**

---

## 🔧 配置位置

### 服务器上的服务文件

文件路径：`/etc/systemd/system/my-fullstack-app.service`

这个文件中的 `Environment=` 行就是设置环境变量的地方。

---

## 📝 当前配置

查看当前的服务文件：

```bash
cat /etc/systemd/system/my-fullstack-app.service
```

你会看到类似这样的配置：

```ini
[Service]
Environment="ALLOWED_ORIGINS=http://YOUR_SERVER_IP,https://YOUR_SERVER_IP"
Environment="HOST=0.0.0.0"
Environment="PORT=8000"
```

---

## 🛠️ 如何修改环境变量

### 方法1：直接编辑服务文件（推荐）

```bash
# 1. 编辑服务文件
sudo vi /etc/systemd/system/my-fullstack-app.service

# 2. 找到 Environment="ALLOWED_ORIGINS=..." 这一行
# 3. 修改为你的服务器 IP 或域名
Environment="ALLOWED_ORIGINS=http://47.112.29.212,https://47.112.29.212"

# 4. 保存退出（vi: 按 Esc，输入 :wq，回车）

# 5. 重新加载并重启服务
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

### 方法2：使用 sed 命令快速修改

```bash
# 修改 ALLOWED_ORIGINS
sudo sed -i 's|ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=http://47.112.29.212,https://47.112.29.212|' /etc/systemd/system/my-fullstack-app.service

# 重新加载并重启
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

### 方法3：从模板文件更新

```bash
# 1. 从项目目录复制模板文件
sudo cp /var/www/my-fullstack-app/deploy/my-fullstack-app.service /etc/systemd/system/

# 2. 替换占位符
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/systemd/system/my-fullstack-app.service

# 3. 重新加载并重启
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

---

## 📋 完整的环境变量列表

当前服务文件中可以配置的环境变量：

| 环境变量 | 说明 | 默认值 | 示例 |
|---------|------|--------|------|
| `ALLOWED_ORIGINS` | 允许的 CORS 来源（逗号分隔） | 本地开发地址 | `http://47.112.29.212,https://47.112.29.212` |
| `HOST` | 服务监听地址 | `127.0.0.1` | `0.0.0.0` |
| `PORT` | 服务端口 | `8000` | `8000` |
| `PATH` | Python 虚拟环境路径 | - | `/var/www/my-fullstack-app/venv/bin` |

---

## 🔍 如何查看当前环境变量

### 方法1：查看服务文件

```bash
cat /etc/systemd/system/my-fullstack-app.service | grep Environment
```

### 方法2：查看运行中的进程环境变量

```bash
# 查看服务进程的环境变量
sudo systemctl show my-fullstack-app --property=Environment
```

### 方法3：在代码中打印（临时调试）

在 `backend/main.py` 中添加：

```python
import os
print("ALLOWED_ORIGINS:", os.getenv("ALLOWED_ORIGINS", "未设置"))
```

然后查看日志：

```bash
sudo journalctl -u my-fullstack-app -n 20
```

---

## 🎯 工作流程

### 本地开发

1. **不设置环境变量** → `main.py` 使用本地地址列表
2. 运行：`python main.py`
3. CORS 允许：`localhost:5173`, `127.0.0.1:5173` 等

### 服务器部署

1. **在 systemd 服务文件中设置环境变量**
   ```ini
   Environment="ALLOWED_ORIGINS=http://47.112.29.212,https://47.112.29.212"
   ```

2. **服务启动时自动读取环境变量**
   - systemd 会设置这些环境变量
   - `main.py` 通过 `os.getenv("ALLOWED_ORIGINS")` 读取

3. **CORS 允许服务器 IP 访问**

---

## 📝 示例：添加新的环境变量

如果你想添加其他环境变量（比如数据库连接等）：

### 1. 修改服务文件

```bash
sudo vi /etc/systemd/system/my-fullstack-app.service
```

添加：

```ini
Environment="DATABASE_URL=postgresql://user:pass@localhost/dbname"
Environment="DEBUG=False"
```

### 2. 在代码中使用

```python
# backend/main.py
database_url = os.getenv("DATABASE_URL", "默认值")
debug = os.getenv("DEBUG", "False") == "True"
```

### 3. 重新加载服务

```bash
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

---

## ⚠️ 重要提示

1. **环境变量只在服务运行时生效**
   - 修改服务文件后必须执行 `systemctl daemon-reload`
   - 然后重启服务 `systemctl restart my-fullstack-app`

2. **环境变量优先级**
   - systemd 服务文件中的环境变量 > 系统环境变量 > 代码默认值

3. **安全性**
   - 不要在代码中硬编码敏感信息（密码、密钥等）
   - 使用环境变量存储敏感配置

4. **本地 vs 服务器**
   - 本地开发：不设置环境变量，使用代码中的默认值
   - 服务器：通过 systemd 服务文件设置环境变量

---

## 🔄 更新流程总结

### 当你修改了代码并推送到 GitHub 后：

```bash
# 1. 在服务器上拉取最新代码
cd /var/www/my-fullstack-app
git pull

# 2. 更新服务文件（如果需要）
sudo cp deploy/my-fullstack-app.service /etc/systemd/system/
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/systemd/system/my-fullstack-app.service

# 3. 重新加载并重启服务
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app

# 4. 验证
sudo systemctl status my-fullstack-app
curl http://localhost:8000/api/data
```

---

## 📚 相关文件

- **服务文件模板**：`deploy/my-fullstack-app.service`
- **服务器上的服务文件**：`/etc/systemd/system/my-fullstack-app.service`
- **代码读取环境变量**：`backend/main.py` 中的 `os.getenv()`

---

## ❓ 常见问题

### Q: 可以在阿里云控制台设置环境变量吗？

**A:** 不可以。环境变量是在服务器上的 systemd 服务文件中配置的，不是在阿里云控制台。

### Q: 修改环境变量后需要重启服务吗？

**A:** 是的，必须执行：
```bash
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

### Q: 如何验证环境变量是否生效？

**A:** 
```bash
# 方法1：查看服务配置
sudo systemctl show my-fullstack-app --property=Environment

# 方法2：查看日志（如果代码中有打印）
sudo journalctl -u my-fullstack-app -n 20
```

### Q: 本地开发时如何设置环境变量？

**A:** 
```bash
# Windows PowerShell
$env:ALLOWED_ORIGINS="http://localhost:5173"
python main.py

# Linux/Mac
export ALLOWED_ORIGINS="http://localhost:5173"
python main.py
```

