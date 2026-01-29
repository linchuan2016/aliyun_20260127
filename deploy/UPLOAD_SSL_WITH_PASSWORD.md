# SSL 证书上传指南（需要密码）

## 问题说明

如果 SSH 连接需要密码，无法通过自动化脚本直接输入密码。请使用以下方法：

---

## 方法一：手动执行命令（推荐）

在 **本地 PowerShell** 中依次执行以下命令，**需要输入密码时输入**：

```powershell
# 1. 切换到项目目录
cd D:\Aliyun\my-fullstack-app

# 2. 创建 SSL 证书目录
ssh root@47.112.29.212 "mkdir -p /etc/nginx/ssl/linchuan.tech"
# 输入密码

ssh root@47.112.29.212 "chmod 700 /etc/nginx/ssl/linchuan.tech"
# 输入密码

# 3. 上传证书文件
scp "ssl\23255505_linchuan.tech_nginx\linchuan.tech.pem" root@47.112.29.212:/etc/nginx/ssl/linchuan.tech/fullchain.pem
# 输入密码

# 4. 上传私钥文件
scp "ssl\23255505_linchuan.tech_nginx\linchuan.tech.key" root@47.112.29.212:/etc/nginx/ssl/linchuan.tech/privkey.pem
# 输入密码

# 5. 设置文件权限
ssh root@47.112.29.212 "chmod 600 /etc/nginx/ssl/linchuan.tech/fullchain.pem"
# 输入密码

ssh root@47.112.29.212 "chmod 600 /etc/nginx/ssl/linchuan.tech/privkey.pem"
# 输入密码

# 6. 验证上传
ssh root@47.112.29.212 "ls -la /etc/nginx/ssl/linchuan.tech/"
# 输入密码
```

---

## 方法二：配置 SSH 密钥认证（推荐，一次配置）

配置后，后续操作将**不再需要输入密码**。

### 步骤 1: 生成 SSH 密钥（如果还没有）

```powershell
# 检查是否已有密钥
Test-Path "$env:USERPROFILE\.ssh\id_rsa"

# 如果没有，生成新密钥
ssh-keygen -t rsa -b 4096 -f "$env:USERPROFILE\.ssh\id_rsa" -N '""'
```

### 步骤 2: 将公钥复制到服务器

**方法 A: 使用 ssh-copy-id（如果可用）**

```powershell
ssh-copy-id root@47.112.29.212
# 输入密码一次
```

**方法 B: 手动复制（如果 ssh-copy-id 不可用）**

```powershell
# 1. 读取公钥内容
$pubKey = Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"

# 2. 复制到服务器（需要输入密码）
ssh root@47.112.29.212 "mkdir -p ~/.ssh && echo '$pubKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

### 步骤 3: 测试无密码登录

```powershell
ssh root@47.112.29.212 "echo 'SSH 密钥配置成功！'"
# 应该不需要输入密码
```

### 步骤 4: 使用脚本上传证书

配置完成后，可以运行：

```powershell
.\deploy\upload-ssl-cert.bat
```

---

## 方法三：使用 WinSCP 图形界面工具

1. 下载安装 [WinSCP](https://winscp.net/)
2. 连接到服务器：
   - 主机名：`47.112.29.212`
   - 用户名：`root`
   - 密码：你的服务器密码
3. 创建目录：`/etc/nginx/ssl/linchuan.tech`
4. 上传文件：
   - `linchuan.tech.pem` → `/etc/nginx/ssl/linchuan.tech/fullchain.pem`
   - `linchuan.tech.key` → `/etc/nginx/ssl/linchuan.tech/privkey.pem`
5. 设置文件权限：
   - `fullchain.pem`: 600
   - `privkey.pem`: 600

---

## 验证上传

无论使用哪种方法，最后验证：

```powershell
ssh root@47.112.29.212 "ls -la /etc/nginx/ssl/linchuan.tech/"
```

应该看到：
- `fullchain.pem` (权限: -rw-------)
- `privkey.pem` (权限: -rw-------)

---

## 下一步

证书上传完成后，继续执行：

1. **同步代码到服务器**
2. **应用 SSL 配置**
3. **重启服务**

详细步骤请参考：`deploy/DEPLOY_SSL.md`

