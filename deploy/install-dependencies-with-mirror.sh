#!/bin/bash
# 使用国内镜像源安装所有依赖
# 在服务器上执行: bash deploy/install-dependencies-with-mirror.sh

set -e

echo "=========================================="
echo "使用国内镜像源安装依赖"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 国内镜像源（阿里云）
MIRROR="https://mirrors.aliyun.com/pypi/simple/"
TRUSTED_HOST="mirrors.aliyun.com"

echo "使用镜像源: 阿里云"
echo "镜像地址: $MIRROR"
echo ""

# 1. 进入项目目录
cd "$DEPLOY_PATH"

# 2. 激活虚拟环境
if [ ! -d "venv" ]; then
    echo "✗ 虚拟环境不存在，请先创建虚拟环境"
    exit 1
fi

source venv/bin/activate

# 3. 升级 pip（使用国内镜像）
echo ">>> 1. 升级 pip..."
pip install --upgrade pip -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --quiet
echo "✓ pip 已升级"
echo ""

# 4. 完全卸载旧版本（避免冲突）
echo ">>> 2. 卸载旧版本（避免冲突）..."
pip uninstall -y fastapi pydantic pydantic-settings pydantic-core uvicorn starlette 2>/dev/null || true
echo "✓ 旧版本已卸载"
echo ""

# 5. 按正确顺序安装（使用国内镜像）
echo ">>> 3. 安装核心依赖（使用国内镜像，按正确顺序）..."

# 先安装 pydantic（确保版本 >= 2.7.0）
echo "安装 Pydantic 2.7+..."
pip install "pydantic>=2.7.0,<3.0.0" -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir
echo "✓ Pydantic 已安装"

# 再安装 pydantic-settings
echo "安装 Pydantic Settings..."
pip install "pydantic-settings>=2.5.0,<3.0.0" -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir
echo "✓ Pydantic Settings 已安装"

# 安装 FastAPI
echo "安装 FastAPI 0.115+..."
pip install "fastapi>=0.115.0,<0.116.0" -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir
echo "✓ FastAPI 已安装"

# 安装 Uvicorn
echo "安装 Uvicorn 0.30+..."
pip install "uvicorn[standard]>=0.30.0,<0.31.0" -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir
echo "✓ Uvicorn 已安装"
echo ""

# 6. 安装其他依赖
echo ">>> 4. 安装其他项目依赖..."
cd backend
pip install -r requirements.txt -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir
cd ..
echo "✓ 所有依赖已安装"
echo ""

# 7. 显示已安装的版本
echo ">>> 5. 已安装的版本："
pip show fastapi pydantic pydantic-settings uvicorn 2>/dev/null | grep -E "^Name|^Version"
echo ""

# 8. 检查版本冲突
echo ">>> 6. 检查版本冲突..."
CONFLICTS=$(pip check 2>&1 | grep -i conflict || echo "")
if [ -n "$CONFLICTS" ]; then
    echo "⚠ 发现版本冲突："
    echo "$CONFLICTS"
    echo ""
    echo "尝试修复..."
    pip install --upgrade --force-reinstall pydantic pydantic-settings -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir
else
    echo "✓ 无版本冲突"
fi
echo ""

# 9. 测试导入
echo ">>> 7. 测试模块导入..."
cd backend
python3 << 'TEST_EOF'
import sys
import os

if not os.path.exists('main.py'):
    print(f"✗ 错误：当前目录 {os.getcwd()} 中没有 main.py")
    sys.exit(1)

try:
    import fastapi
    import pydantic
    from fastapi import Depends
    from fastapi.security import OAuth2PasswordRequestForm
    
    print(f"✓ FastAPI {fastapi.__version__} 导入成功")
    print(f"✓ Pydantic {pydantic.__version__} 导入成功")
    
    from fastapi.dependencies.utils import get_dependant
    print("✓ Depends 工具函数可用")
    
    print("测试导入应用模块...")
    from main import app
    print("✓ 应用模块导入成功")
    print("✓ 所有测试通过！")
    sys.exit(0)
except Exception as e:
    print(f"✗ 导入失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
TEST_EOF

TEST_RESULT=$?
cd ..

if [ $TEST_RESULT -ne 0 ]; then
    echo ""
    echo "✗ 测试失败"
    deactivate
    exit 1
fi

deactivate

echo ""
echo "=========================================="
echo "✓ 安装完成！所有依赖已使用国内镜像安装"
echo "=========================================="
echo ""

