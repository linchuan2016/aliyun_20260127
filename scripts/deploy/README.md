# 部署配置说明

本目录包含阿里云服务器部署所需的所有配置文件。

## 文件说明

### 服务配置

- **`my-fullstack-app.service`** - HTTP 版本的 systemd 服务配置
- **`my-fullstack-app-ssl.service`** - HTTPS 版本的 systemd 服务配置（支持 SSL）

### Nginx 配置

- **`nginx.conf`** - HTTP 版本的 Nginx 配置
- **`nginx-ssl.conf`** - HTTPS 版本的 Nginx 配置（包含 SSL 证书配置）
- **`nginx-attu.conf`** - Attu 管理界面的 Nginx 反向代理配置

### Milvus 和 Attu 部署

- **`milvus-docker-compose.yml`** - Milvus 和 Attu 的 Docker Compose 配置文件
- **`deploy-milvus-aliyun-complete.sh`** - 一键完整部署脚本（推荐使用）
- **`deploy-milvus.sh`** - 基础部署脚本（需要已安装 Docker）
- **`quick-deploy-milvus.sh`** - 快速部署脚本（自动安装 Docker）
- **`install-docker-aliyun.sh`** - Docker 安装脚本（使用阿里云镜像源）
- **`install-docker-compose.sh`** - Docker Compose 安装脚本
- **`configure-firewall.sh`** - 防火墙配置脚本
- **`verify-milvus-deployment.sh`** - 部署验证脚本
- **`DEPLOY_MILVUS_ALIYUN.md`** - 详细的阿里云部署指南
- **`DEPLOY_MILVUS.md`** - 通用部署指南

### 其他部署脚本

- **`apply-ssl-complete-fixed.sh`** - 一键应用 SSL 配置的脚本（在服务器上执行）
- **`upload-ssl-cert.bat`** - Windows 下上传 SSL 证书的批处理脚本
- **`upload-ssl-cert.ps1`** - PowerShell 版本的 SSL 证书上传脚本
- **`sync-to-server.ps1`** - 代码同步到服务器的脚本

## Milvus 和 Attu 部署（阿里云）

### 方法一：一键完整部署（推荐）

```bash
# 在服务器上执行
cd /var/www/my-fullstack-app
git pull gitee main

# 执行完整部署脚本（会自动安装 Docker、配置防火墙、启动服务）
chmod +x scripts/deploy/deploy-milvus-aliyun-complete.sh
sudo ./scripts/deploy/deploy-milvus-aliyun-complete.sh
```

### 方法二：分步部署

```bash
# 1. 安装 Docker（如果未安装）
chmod +x scripts/deploy/install-docker-aliyun.sh
sudo ./scripts/deploy/install-docker-aliyun.sh

# 2. 安装 Docker Compose（如果未安装）
chmod +x scripts/deploy/install-docker-compose.sh
sudo ./scripts/deploy/install-docker-compose.sh

# 3. 配置防火墙
chmod +x scripts/deploy/configure-firewall.sh
sudo ./scripts/deploy/configure-firewall.sh

# 4. 部署 Milvus 和 Attu
chmod +x scripts/deploy/deploy-milvus.sh
sudo ./scripts/deploy/deploy-milvus.sh
```

### 验证部署

```bash
# 验证部署状态
chmod +x scripts/deploy/verify-milvus-deployment.sh
./scripts/deploy/verify-milvus-deployment.sh
```

### 访问服务

- **Attu 管理界面**: `http://YOUR_SERVER_IP:3000`
- **Milvus API**: `localhost:19530` 或 `YOUR_SERVER_IP:19530`
- **MinIO 控制台**: `http://YOUR_SERVER_IP:9001`

首次访问 Attu 时：
1. 打开 `http://YOUR_SERVER_IP:3000`
2. Milvus 地址填写：`milvus-standalone:19530`（容器内）或 `localhost:19530`（外部）
3. 用户名和密码留空（默认配置）

### 服务管理

```bash
cd /opt/milvus

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 停止并删除数据（谨慎操作）
docker-compose down -v
```

### 配置 Nginx 反向代理（可选）

如果需要通过域名访问 Attu：

```bash
# 复制 Nginx 配置
sudo cp scripts/deploy/nginx-attu.conf /etc/nginx/conf.d/attu.conf

# 编辑配置文件，修改 server_name
sudo nano /etc/nginx/conf.d/attu.conf

# 测试配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx
```

### 常见问题

1. **端口无法访问**
   - 检查防火墙：`sudo firewall-cmd --list-ports`
   - 检查阿里云安全组是否开放端口 3000 和 19530
   - 运行 `scripts/deploy/configure-firewall.sh` 配置防火墙

2. **服务启动失败**
   - 查看日志：`cd /opt/milvus && docker-compose logs -f`
   - 检查内存：`free -h`（Milvus 需要至少 2GB 内存）

3. **Docker 镜像下载慢**
   - 脚本已配置阿里云镜像加速
   - 如果仍有问题，检查 `/etc/docker/daemon.json`

详细说明请参考：
- `DEPLOY_MILVUS_ALIYUN.md` - 阿里云部署详细指南
- `DEPLOY_MILVUS.md` - 通用部署指南

---

## 快速部署流程

### 1. 基础部署（HTTP）

```bash
# 在服务器上
cd /var/www/my-fullstack-app

# 复制 Nginx 配置
sudo cp scripts/deploy/nginx.conf /etc/nginx/conf.d/my-fullstack-app.conf
# 或
sudo cp scripts/deploy/nginx.conf /etc/nginx/sites-available/my-fullstack-app
sudo ln -s /etc/nginx/sites-available/my-fullstack-app /etc/nginx/sites-enabled/

# 复制 systemd 配置
sudo cp scripts/deploy/my-fullstack-app.service /etc/systemd/system/

# 启动服务
sudo systemctl daemon-reload
sudo systemctl enable my-fullstack-app
sudo systemctl start my-fullstack-app
sudo systemctl restart nginx
```

### 2. SSL 部署（HTTPS）

#### 步骤 1: 上传 SSL 证书

在 Windows 本地执行：

```powershell
.\deploy\upload-ssl-cert.bat
```

或手动上传：

```bash
# 在服务器上创建目录
sudo mkdir -p /etc/nginx/ssl/linchuan.tech
sudo chmod 700 /etc/nginx/ssl/linchuan.tech

# 上传证书文件（在本地执行 scp）
scp ssl/23255505_linchuan.tech_nginx/linchuan.tech.pem root@47.112.29.212:/etc/nginx/ssl/linchuan.tech/fullchain.pem
scp ssl/23255505_linchuan.tech_nginx/linchuan.tech.key root@47.112.29.212:/etc/nginx/ssl/linchuan.tech/privkey.pem

# 设置权限
ssh root@47.112.29.212 "chmod 600 /etc/nginx/ssl/linchuan.tech/*.pem"
```

#### 步骤 2: 应用 SSL 配置

在服务器上执行：

```bash
cd /var/www/my-fullstack-app
chmod +x scripts/deploy/apply-ssl-complete-fixed.sh
sudo ./scripts/deploy/apply-ssl-complete-fixed.sh
```

#### 步骤 3: 重启服务

```bash
sudo systemctl restart my-fullstack-app
sudo systemctl restart nginx
```

## 环境变量配置

### HTTP 版本

编辑 `/etc/systemd/system/my-fullstack-app.service`：

```ini
Environment="ALLOWED_ORIGINS=http://YOUR_SERVER_IP,https://YOUR_SERVER_IP"
```

### HTTPS 版本

编辑 `/etc/systemd/system/my-fullstack-app-ssl.service`：

```ini
Environment="ALLOWED_ORIGINS=https://linchuan.tech,https://www.linchuan.tech,http://localhost:5173,http://127.0.0.1:5173"
```

修改后需要重新加载并重启：

```bash
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
```

## 验证部署

### 检查服务状态

```bash
# 检查后端服务
sudo systemctl status my-fullstack-app

# 检查 Nginx
sudo systemctl status nginx

# 查看日志
sudo journalctl -u my-fullstack-app -f
sudo tail -f /var/log/nginx/error.log
```

### 测试访问

- HTTP: `http://YOUR_SERVER_IP`
- HTTPS: `https://linchuan.tech`

## 常见问题

### 1. Nginx 配置目录不同

阿里云 Linux 通常使用 `/etc/nginx/conf.d/`，Ubuntu/Debian 使用 `/etc/nginx/sites-available/`。

脚本 `apply-ssl-complete-fixed.sh` 会自动检测并使用正确的目录。

### 2. 权限问题

确保：
- SSL 证书文件权限为 `600`
- SSL 证书目录权限为 `700`
- Nginx 用户有读取证书的权限

### 3. CORS 错误

检查 `ALLOWED_ORIGINS` 环境变量是否包含前端域名。

### 4. 端口被占用

```bash
# 检查端口占用
sudo netstat -tlnp | grep :8000
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

## 更新代码

### 方法一：仅同步代码（最快）

```bash
# 在服务器上执行
cd /var/www/my-fullstack-app && \
git stash push -m backup 2>/dev/null || true && \
git fetch gitee main && \
git reset --hard gitee/main
```

### 方法二：使用完整同步脚本（推荐）

```bash
# 在服务器上执行
cd /var/www/my-fullstack-app
bash scripts/deploy/sync-on-server-complete.sh
```

### 方法三：使用本地同步脚本

```powershell
# 在 Windows 本地执行
.\deploy\sync-quick.ps1
```

### 方法四：手动更新

```bash
# 在服务器上
cd /var/www/my-fullstack-app

# 拉取最新代码
git stash push -m backup 2>/dev/null || true
git fetch gitee main
git reset --hard gitee/main

# 更新后端依赖
source venv/bin/activate
cd backend
pip install -r requirements.txt --quiet
python init_db.py
cd ..

# 构建前端
cd frontend
npm install --silent
npm run build
cd ..

# 重启服务
sudo systemctl daemon-reload
sudo systemctl restart my-fullstack-app
sleep 3
sudo systemctl restart nginx
```

### 解决 Git Pull 冲突

如果 `git pull` 时遇到 `package-lock.json` 冲突：

```bash
# 方法一：暂存本地更改（推荐）
git stash
git pull gitee main

# 方法二：丢弃本地更改（最简单）
git checkout -- frontend/package-lock.json
git pull gitee main
```

## 更新图标路径

如果服务器上的图标仍然依赖外部服务，需要更新数据库中的图标路径：

```bash
# 在服务器上执行
cd /var/www/my-fullstack-app
chmod +x scripts/deploy/update-icons-on-server.sh
./scripts/deploy/update-icons-on-server.sh
```

或手动执行：

```bash
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python update_icons.py
sudo systemctl restart my-fullstack-app
```

