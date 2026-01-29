# 修复阿里云服务器编译工具缺失问题

## 问题描述

在安装 Python 依赖时出现错误：
```
gcc: fatal error: cannot execute 'cc1plus': execvp: No such file or directory
```

这是因为服务器缺少 C++ 编译器，无法编译 `greenlet` 等需要 C++ 扩展的包。

---

## 解决方案

### 方法一：使用修复脚本（推荐）

```bash
# 在服务器上执行
cd /var/www/my-fullstack-app
chmod +x deploy/fix-compiler.sh
./deploy/fix-compiler.sh
```

### 方法二：手动安装

#### 对于 CentOS/RHEL/Alibaba Cloud Linux：

```bash
# 安装编译工具
sudo yum install -y gcc gcc-c++ python3-devel

# 或者如果使用 dnf
sudo dnf install -y gcc gcc-c++ python3-devel
```

#### 对于 Debian/Ubuntu：

```bash
sudo apt-get update
sudo apt-get install -y build-essential python3-dev
```

---

## 安装完成后的步骤

### 1. 升级 pip（推荐）

```bash
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
pip install --upgrade pip
```

### 2. 重新安装依赖

```bash
pip install -r requirements.txt
```

### 3. 初始化数据库

```bash
python init_db.py
```

### 4. 构建前端

```bash
cd /var/www/my-fullstack-app/frontend
npm install
npm run build
```

### 5. 重启服务

```bash
sudo systemctl restart my-fullstack-app
sudo systemctl restart nginx
```

---

## 一键修复命令

如果已经 SSH 连接到服务器，可以执行：

```bash
# 安装编译工具
sudo yum install -y gcc gcc-c++ python3-devel

# 进入项目目录
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate

# 升级 pip
pip install --upgrade pip

# 重新安装依赖
pip install -r requirements.txt

# 初始化数据库
python init_db.py

# 构建前端
cd ../frontend
npm install
npm run build

# 重启服务
sudo systemctl restart my-fullstack-app
sudo systemctl restart nginx
```

---

## 验证安装

```bash
# 检查 gcc 和 g++
gcc --version
g++ --version

# 检查 Python 开发头文件
python3-config --includes
```

---

## 常见问题

### 问题 1: yum 命令不存在

**解决：** 使用 `dnf` 或 `apt-get`（取决于系统）

### 问题 2: 权限不足

**解决：** 使用 `sudo` 执行安装命令

### 问题 3: 网络问题导致安装失败

**解决：** 
```bash
# 更新软件源
sudo yum update -y

# 或
sudo apt-get update
```



