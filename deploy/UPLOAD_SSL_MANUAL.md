# SSL 证书手动上传指南

如果 PowerShell 脚本无法运行，可以使用以下手动命令。

---

## 步骤 1: 准备证书文件

确保你有以下两个文件：
- **证书文件**（`.pem` 或 `.crt`）- 通常包含域名证书和中间证书
- **私钥文件**（`.key`）

---

## 步骤 2: 在 PowerShell 中执行以下命令

### 2.1 设置变量（请替换为你的实际文件路径）

```powershell
# 设置证书文件路径（请替换为你的实际路径）
$CertPath = "C:\path\to\your\certificate.pem"
$KeyPath = "C:\path\to\your\private.key"

# 服务器信息（通常不需要修改）
$ServerIP = "47.112.29.212"
$ServerUser = "root"
```

### 2.2 创建 SSL 证书目录

```powershell
ssh "${ServerUser}@${ServerIP}" "mkdir -p /etc/nginx/ssl/linchuan.tech && chmod 700 /etc/nginx/ssl/linchuan.tech"
```

### 2.3 上传证书文件

```powershell
# 上传证书文件
scp $CertPath "${ServerUser}@${ServerIP}:/etc/nginx/ssl/linchuan.tech/fullchain.pem"

# 上传私钥文件
scp $KeyPath "${ServerUser}@${ServerIP}:/etc/nginx/ssl/linchuan.tech/privkey.pem"
```

### 2.4 设置文件权限

```powershell
ssh "${ServerUser}@${ServerIP}" "chmod 600 /etc/nginx/ssl/linchuan.tech/fullchain.pem && chmod 600 /etc/nginx/ssl/linchuan.tech/privkey.pem"
```

---

## 完整命令示例

**一次性执行（替换文件路径）：**

```powershell
# 设置变量
$CertPath = "C:\Users\Admin\Downloads\linchuan.tech.pem"
$KeyPath = "C:\Users\Admin\Downloads\linchuan.tech.key"
$ServerIP = "47.112.29.212"
$ServerUser = "root"

# 创建目录
ssh "${ServerUser}@${ServerIP}" "mkdir -p /etc/nginx/ssl/linchuan.tech && chmod 700 /etc/nginx/ssl/linchuan.tech"

# 上传文件
scp $CertPath "${ServerUser}@${ServerIP}:/etc/nginx/ssl/linchuan.tech/fullchain.pem"
scp $KeyPath "${ServerUser}@${ServerIP}:/etc/nginx/ssl/linchuan.tech/privkey.pem"

# 设置权限
ssh "${ServerUser}@${ServerIP}" "chmod 600 /etc/nginx/ssl/linchuan.tech/fullchain.pem && chmod 600 /etc/nginx/ssl/linchuan.tech/privkey.pem"
```

---

## 验证上传

```powershell
# 检查文件是否存在
ssh root@47.112.29.212 "ls -la /etc/nginx/ssl/linchuan.tech/"
```

应该看到：
- `fullchain.pem`
- `privkey.pem`

---

## 下一步

证书上传完成后，继续执行：

1. **同步代码到服务器**
2. **应用 SSL 配置**
3. **重启服务**

详细步骤请参考：`deploy/DEPLOY_SSL.md`

