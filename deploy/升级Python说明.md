# 阿里云服务器 Python 版本升级指南

## 当前情况

- **本地 Python 版本**: 3.14.2
- **服务器 Python 版本**: 可能是 3.6 或更早（需要检查）

## 升级方案

### 方案一：升级到 Python 3.10（推荐）

**优点：**
- 稳定可靠，广泛使用
- 支持所有需要的特性（fromisoformat, typing 等）
- 性能良好
- 长期支持

**步骤：**

1. **在服务器上执行升级脚本**
   ```bash
   cd /var/www/my-fullstack-app
   bash deploy/升级Python版本.sh
   ```

2. **或者手动执行**
   ```bash
   # 1. 安装编译依赖
   sudo yum groupinstall -y "Development Tools"
   sudo yum install -y openssl-devel bzip2-devel libffi-devel zlib-devel
   
   # 2. 下载并编译 Python 3.10
   cd /tmp
   wget https://www.python.org/ftp/python/3.10.13/Python-3.10.13.tgz
   tar -xzf Python-3.10.13.tgz
   cd Python-3.10.13
   ./configure --enable-optimizations --with-ensurepip=install --prefix=/usr/local
   make -j$(nproc)
   sudo make altinstall
   
   # 3. 更新虚拟环境
   cd /var/www/my-fullstack-app
   mv venv venv.backup
   /usr/local/bin/python3.10 -m venv venv
   source venv/bin/activate
   pip install --upgrade pip
   cd backend
   pip install -r requirements.txt
   
   # 4. 重启服务
   sudo systemctl restart my-fullstack-app
   ```

### 方案二：使用 pyenv（更灵活）

```bash
# 1. 安装 pyenv
curl https://pyenv.run | bash

# 2. 配置环境变量
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc

# 3. 安装 Python 3.10
pyenv install 3.10.13

# 4. 在项目目录设置版本
cd /var/www/my-fullstack-app
pyenv local 3.10.13

# 5. 重建虚拟环境
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r backend/requirements.txt
```

## 兼容性检查

升级后，运行兼容性检查：

```bash
cd /var/www/my-fullstack-app
python3 deploy/检查Python兼容性.py
```

或者在服务器上直接测试：

```bash
cd /var/www/my-fullstack-app/backend
source ../venv/bin/activate
python3 -c "
import sys
print(f'Python: {sys.version}')
from database import SessionLocal
from models import Article
print('✓ 导入成功')
"
```

## 注意事项

1. **备份虚拟环境**
   - 升级前会自动备份旧虚拟环境
   - 如果出现问题，可以恢复：`mv venv.backup.* venv`

2. **检查服务状态**
   ```bash
   sudo systemctl status my-fullstack-app
   journalctl -u my-fullstack-app -n 50 --no-pager
   ```

3. **测试 API**
   ```bash
   curl http://127.0.0.1:8000/api/health
   curl http://127.0.0.1:8000/api/articles
   ```

## 回滚方案

如果升级后出现问题：

```bash
# 恢复旧虚拟环境
cd /var/www/my-fullstack-app
mv venv venv.new
mv venv.backup.* venv

# 重启服务
sudo systemctl restart my-fullstack-app
```

## 推荐版本

- **Python 3.10.13** - 稳定，推荐用于生产环境
- **Python 3.11.x** - 性能更好，但相对较新
- **不推荐 3.14.x** - 太新，生产环境可能不稳定

## 建议

1. **服务器使用 Python 3.10**（稳定可靠）
2. **本地可以使用 3.14**（开发体验好）
3. **通过代码兼容性处理**（如已实现的 parse_iso_date）确保兼容性
4. **在 requirements.txt 中锁定依赖版本**

