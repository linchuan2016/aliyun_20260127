# 阿里云服务器创建虚拟环境 - 详细步骤

本文档将一步步教你如何在阿里云服务器上创建 Python 虚拟环境。

---

## 前置准备

1. ✅ 已购买阿里云轻量级服务器
2. ✅ 知道服务器的 IP 地址
3. ✅ 知道 root 密码（或已配置 SSH 密钥）
4. ✅ 已上传代码到服务器（不包括 venv 文件夹）

---

## 第一步：SSH 登录服务器

### Windows 用户（PowerShell 或 CMD）

```powershell
# 使用密码登录
ssh root@你的服务器IP

# 例如：
ssh root@123.456.789.123
```

**输入密码后按回车**（输入密码时不会显示字符，这是正常的）

### 如果连接成功，你会看到类似这样的提示：

```
Welcome to Alibaba Cloud Elastic Compute Service !
[root@iZxxxxx ~]#
```

---

## 第二步：检查 Python 环境

登录后，先检查服务器上是否已安装 Python：

```bash
# 检查 Python 3 是否安装
python3 --version

# 检查 pip 是否安装
python3 -m pip --version
```

**预期输出：**
```
Python 3.x.x
pip x.x.x from /usr/lib/python3.x/site-packages/pip (python 3.x)
```

### 如果没有安装 Python，先安装：

```bash
# 更新系统
sudo yum update -y

# 安装 Python 3 和 pip
sudo yum install -y python3 python3-pip

# 验证安装
python3 --version
pip3 --version
```

---

## 第三步：进入项目目录

```bash
# 进入项目目录（假设你已经上传了代码）
cd /var/www/my-fullstack-app

# 查看目录结构，确认文件已上传
ls -la
```

**应该能看到：**
- `backend/` 文件夹
- `frontend/` 文件夹
- `deploy/` 文件夹
- **不应该有** `venv/` 文件夹（如果有，删除它）

### 如果看到 venv 文件夹，删除它：

```bash
rm -rf venv
```

---

## 第四步：进入后端目录

```bash
cd backend

# 查看文件
ls -la
```

**应该能看到：**
- `main.py`
- `requirements.txt`
- `start.sh`

---

## 第五步：创建虚拟环境

```bash
# 在 backend 目录下，创建虚拟环境到上一级目录
python3 -m venv ../venv
```

**命令解释：**
- `python3 -m venv` - 使用 Python 3 创建虚拟环境
- `../venv` - 虚拟环境创建在上一级目录（即 `/var/www/my-fullstack-app/venv`）

**执行后，你会看到类似输出：**
```
（可能没有输出，这是正常的）
```

### 验证虚拟环境是否创建成功：

```bash
# 返回上一级目录
cd ..

# 查看 venv 文件夹
ls -la venv/
```

**应该能看到：**
```
bin/    include/    lib/    lib64/    pyvenv.cfg
```

---

## 第六步：激活虚拟环境

```bash
# 激活虚拟环境
source venv/bin/activate
```

**激活成功后，命令行提示符会变化：**

**激活前：**
```
[root@iZxxxxx my-fullstack-app]#
```

**激活后：**
```
(venv) [root@iZxxxxx my-fullstack-app]#
```

**注意前面的 `(venv)` 标识，表示虚拟环境已激活！**

---

## 第七步：升级 pip

```bash
# 升级 pip 到最新版本
pip install --upgrade pip
```

**预期输出：**
```
Requirement already satisfied: pip in ./venv/lib/python3.x/site-packages (x.x.x)
Collecting pip
  Downloading pip-x.x.x-py3-none-any.whl (x.x MB)
     ━━━━━━━━━━━━━━━━━━━━━━━ 100% x.x MB
Installing collected packages: pip
Successfully installed pip-x.x.x
```

---

## 第八步：安装项目依赖

```bash
# 进入 backend 目录
cd backend

# 安装 requirements.txt 中的所有依赖
pip install -r requirements.txt
```

**预期输出：**
```
Collecting fastapi
  Downloading fastapi-x.x.x-py3-none-any.whl
Collecting uvicorn
  Downloading uvicorn-x.x.x-py3-none-any.whl
...
Installing collected packages: ...
Successfully installed fastapi-x.x.x uvicorn-x.x.x ...
```

**这个过程可能需要几分钟，请耐心等待。**

---

## 第九步：验证安装

```bash
# 检查已安装的包
pip list
```

**应该能看到：**
```
Package    Version
---------- -------
fastapi    x.x.x
uvicorn    x.x.x
pip        x.x.x
...
```

### 测试后端是否能运行：

```bash
# 测试运行（在 backend 目录下）
python main.py
```

**预期输出：**
```
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

**看到这个输出说明成功了！按 `Ctrl+C` 停止测试。**

---

## 第十步：退出虚拟环境（可选）

测试完成后，可以退出虚拟环境：

```bash
# 退出虚拟环境
deactivate
```

**提示符会变回：**
```
[root@iZxxxxx my-fullstack-app]#
```

**注意：** 下次使用时需要重新激活虚拟环境。

---

## 完整命令总结（复制粘贴版）

```bash
# 1. 登录服务器（在本地执行）
ssh root@你的服务器IP

# 2. 检查 Python（在服务器上执行）
python3 --version
pip3 --version

# 3. 如果没有 Python，安装它
sudo yum update -y
sudo yum install -y python3 python3-pip

# 4. 进入项目目录
cd /var/www/my-fullstack-app

# 5. 如果存在旧的 venv，删除它
rm -rf venv

# 6. 进入后端目录
cd backend

# 7. 创建虚拟环境
python3 -m venv ../venv

# 8. 激活虚拟环境
source ../venv/bin/activate

# 9. 升级 pip
pip install --upgrade pip

# 10. 安装依赖
pip install -r requirements.txt

# 11. 验证安装
pip list

# 12. 测试运行（可选）
python main.py
# 按 Ctrl+C 停止

# 13. 退出虚拟环境（可选）
deactivate
```

---

## 常见问题

### 问题1：`python3: command not found`

**原因：** 服务器没有安装 Python 3

**解决：**
```bash
sudo yum install -y python3 python3-pip
```

---

### 问题2：`python3: No module named venv`

**原因：** Python 3 没有安装 venv 模块

**解决：**
```bash
# 安装 Python 开发工具
sudo yum install -y python3-devel

# 或者使用 virtualenv
sudo yum install -y python3-pip
pip3 install virtualenv
python3 -m virtualenv ../venv
```

---

### 问题3：`pip: command not found`

**原因：** pip 没有安装

**解决：**
```bash
sudo yum install -y python3-pip
```

---

### 问题4：`Permission denied`

**原因：** 权限不足

**解决：**
```bash
# 确保使用 root 用户，或使用 sudo
sudo python3 -m venv ../venv
```

---

### 问题5：激活虚拟环境后提示符没有变化

**检查：**
```bash
# 检查是否真的激活了
which python
# 应该显示：/var/www/my-fullstack-app/venv/bin/python

# 检查 pip 路径
which pip
# 应该显示：/var/www/my-fullstack-app/venv/bin/pip
```

---

## 下一步

虚拟环境创建完成后，继续：

1. ✅ 构建前端：`cd frontend && npm install && npm run build`
2. ✅ 配置 systemd 服务：参考 `deploy/DEPLOY_ALIBABA_CLOUD_LINUX.md`
3. ✅ 配置 Nginx：参考部署文档
4. ✅ 启动服务：`sudo systemctl start my-fullstack-app`

---

## 提示

- 💡 **每次 SSH 登录后，如果需要使用虚拟环境，都要先激活：**
  ```bash
  source /var/www/my-fullstack-app/venv/bin/activate
  ```

- 💡 **虚拟环境路径是：** `/var/www/my-fullstack-app/venv`

- 💡 **激活后，所有 pip 安装的包都会安装到这个虚拟环境中**

- 💡 **systemd 服务会自动使用这个虚拟环境，不需要手动激活**

