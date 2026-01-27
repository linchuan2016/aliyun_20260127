# 代码上传指南

## ⚠️ 重要提示

**不要上传以下文件夹/文件到服务器：**

- ❌ `venv/` - Python 虚拟环境（必须在服务器上重新创建）
- ❌ `frontend/node_modules/` - Node.js 依赖（会在服务器上重新安装）
- ❌ `frontend/dist/` - 前端构建文件（会在服务器上重新构建）
- ❌ `backend/__pycache__/` - Python 缓存文件
- ❌ `.DS_Store` - macOS 系统文件

这些文件/文件夹已经在 `.gitignore` 中被忽略，如果使用 Git 上传会自动排除。

---

## 上传方式

### 方式一：使用 Git（推荐）

**优点：**
- 自动排除 `.gitignore` 中的文件
- 版本控制，方便更新
- 不会上传不必要的文件

**步骤：**
```bash
# 在服务器上执行
git clone <your-repo-url> /var/www/my-fullstack-app
```

---

### 方式二：使用 SCP（手动上传）

**如果使用 SCP，需要手动排除不需要的文件。**

#### Windows PowerShell 方法：

```powershell
# 1. 在服务器上创建目录
ssh root@your-server-ip "mkdir -p /var/www/my-fullstack-app"

# 2. 分别上传需要的文件夹（排除 venv）
scp -r D:\Aliyun\my-fullstack-app\backend root@your-server-ip:/var/www/my-fullstack-app/
scp -r D:\Aliyun\my-fullstack-app\frontend root@your-server-ip:/var/www/my-fullstack-app/
scp -r D:\Aliyun\my-fullstack-app\deploy root@your-server-ip:/var/www/my-fullstack-app/

# 3. 上传 .gitignore（可选）
scp D:\Aliyun\my-fullstack-app\.gitignore root@your-server-ip:/var/www/my-fullstack-app/
```

#### 使用 rsync（如果服务器支持，推荐）：

```bash
# rsync 可以自动排除文件
rsync -av --exclude='venv' --exclude='node_modules' --exclude='dist' --exclude='__pycache__' \
  D:\Aliyun\my-fullstack-app\ root@your-server-ip:/var/www/my-fullstack-app/
```

---

## 为什么不能上传 venv？

### 1. **平台不兼容**
- Windows 的 `venv` 包含 Windows 特定的路径（如 `Scripts\activate.bat`）
- Linux 的 `venv` 包含 Linux 特定的路径（如 `bin/activate`）
- 两者完全不兼容

### 2. **系统路径不同**
- 虚拟环境包含绝对路径
- 本地路径：`D:\Aliyun\my-fullstack-app\venv`
- 服务器路径：`/var/www/my-fullstack-app/venv`
- 路径不匹配会导致无法使用

### 3. **Python 版本可能不同**
- 本地 Python 版本可能与服务器不同
- 虚拟环境绑定特定 Python 版本
- 需要重新创建以匹配服务器环境

### 4. **文件大小**
- `venv` 文件夹通常很大（几百MB）
- 上传浪费时间
- 服务器上重新创建更快

---

## 正确的部署流程

### 1. 上传代码（不包含 venv）
```bash
# 使用 Git 或 SCP（排除 venv）
```

### 2. 在服务器上创建虚拟环境
```bash
cd /var/www/my-fullstack-app/backend
python3 -m venv ../venv
source ../venv/bin/activate
pip install -r requirements.txt
```

### 3. 安装前端依赖并构建
```bash
cd /var/www/my-fullstack-app/frontend
npm install
npm run build
```

---

## 检查清单

上传前检查：

- ✅ `backend/` 文件夹（包含 `main.py` 和 `requirements.txt`）
- ✅ `frontend/` 文件夹（包含 `src/`、`package.json` 等）
- ✅ `deploy/` 文件夹（包含部署脚本和配置）
- ✅ `.gitignore` 文件（可选）
- ❌ `venv/` 文件夹（不要上传）
- ❌ `frontend/node_modules/`（不要上传）
- ❌ `frontend/dist/`（不要上传）

---

## 常见错误

### 错误1：上传了 venv 文件夹
**症状：** 服务器上无法激活虚拟环境，或出现路径错误

**解决：** 删除服务器上的 venv 文件夹，重新创建：
```bash
rm -rf /var/www/my-fullstack-app/venv
cd /var/www/my-fullstack-app/backend
python3 -m venv ../venv
source ../venv/bin/activate
pip install -r requirements.txt
```

### 错误2：上传了 node_modules
**症状：** 上传时间很长，文件很大

**解决：** 删除 node_modules，重新安装：
```bash
rm -rf /var/www/my-fullstack-app/frontend/node_modules
cd /var/www/my-fullstack-app/frontend
npm install
```

---

## 总结

**记住：**
1. ✅ 上传源代码（`.py`、`.vue`、`.json` 等）
2. ✅ 上传配置文件（`requirements.txt`、`package.json` 等）
3. ❌ 不要上传生成的文件（`venv`、`node_modules`、`dist`）
4. ✅ 在服务器上重新创建虚拟环境和安装依赖

