# 从 GitHub 克隆代码到阿里云服务器

## 快速步骤

### 1. SSH 登录服务器

在本地 PowerShell 执行：

```powershell
ssh root@47.112.29.212
```

输入密码后登录。

---

### 2. 在服务器上安装 Git（如果还没安装）

```bash
# 检查 Git 是否已安装
git --version

# 如果没有安装，执行：
sudo yum install -y git
```

---

### 3. 克隆代码

```bash
# 克隆 GitHub 仓库到服务器
git clone https://github.com/linchuan2016/aliyun_20260127.git /var/www/my-fullstack-app
```

**或者使用脚本：**

```bash
# 下载并执行克隆脚本
curl -o clone.sh https://raw.githubusercontent.com/linchuan2016/aliyun_20260127/main/deploy/clone-from-github.sh
chmod +x clone.sh
sudo ./clone.sh
```

---

### 4. 验证代码已克隆

```bash
# 进入项目目录
cd /var/www/my-fullstack-app

# 查看文件
ls -la
```

**应该能看到：**
- `backend/` 文件夹
- `frontend/` 文件夹
- `deploy/` 文件夹
- `.gitignore` 文件

---

### 5. 继续部署

参考部署文档：
- `deploy/CREATE_VENV_STEP_BY_STEP.md` - 创建虚拟环境
- `deploy/DEPLOY_ALIBABA_CLOUD_LINUX.md` - 完整部署指南

---

## 完整命令（一键复制）

```bash
# 1. 登录服务器（在本地执行）
ssh root@47.112.29.212

# 2. 安装 Git（如果未安装）
sudo yum install -y git

# 3. 克隆代码
git clone https://github.com/linchuan2016/aliyun_20260127.git /var/www/my-fullstack-app

# 4. 进入项目目录
cd /var/www/my-fullstack-app

# 5. 查看文件
ls -la
```

---

## 常见问题

### Q1: `git: command not found`

**解决：**
```bash
sudo yum install -y git
```

### Q2: `Permission denied`

**解决：**
```bash
# 确保有权限创建目录
sudo mkdir -p /var/www
sudo chown -R $USER:$USER /var/www
```

### Q3: 克隆很慢

**原因：** GitHub 在国内访问可能较慢

**解决：**
- 使用 Gitee 镜像（如果有）
- 或者使用代理
- 或者从本地 SCP 上传

### Q4: 如何更新代码？

```bash
cd /var/www/my-fullstack-app
git pull
```

---

## 后续步骤

代码克隆完成后：

1. ✅ 创建虚拟环境
2. ✅ 安装后端依赖
3. ✅ 构建前端
4. ✅ 配置 systemd 服务
5. ✅ 配置 Nginx
6. ✅ 启动服务

参考：`deploy/DEPLOY_ALIBABA_CLOUD_LINUX.md`

