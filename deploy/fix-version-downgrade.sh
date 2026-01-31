#!/bin/bash
# 修复版本回退问题
# 在服务器上执行: bash deploy/fix-version-downgrade.sh

set -e

echo "=========================================="
echo "修复版本回退问题"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"
MIRROR="https://mirrors.aliyun.com/pypi/simple/"
HOST="mirrors.aliyun.com"

cd "$DEPLOY_PATH"
source venv/bin/activate

# 显示当前版本
echo ">>> 当前版本："
pip show fastapi uvicorn pydantic 2>/dev/null | grep -E "^Name|^Version" || echo "未安装"
echo ""

# 检查是否有旧版本
FASTAPI_VERSION=$(pip show fastapi 2>/dev/null | grep "^Version" | awk '{print $2}' || echo "")
if [ -n "$FASTAPI_VERSION" ]; then
    echo "当前 FastAPI 版本: $FASTAPI_VERSION"
    if [[ "$FASTAPI_VERSION" < "0.115.0" ]]; then
        echo "⚠ 检测到旧版本，需要升级"
    else
        echo "✓ 版本正确"
    fi
fi
echo ""

# 完全卸载并重新安装
echo ">>> 完全卸载并重新安装..."

# 卸载所有相关包
pip uninstall -y fastapi uvicorn starlette pydantic pydantic-settings pydantic-core 2>/dev/null || true
sleep 1

# 按正确顺序强制安装
echo "安装 Pydantic 2.7+..."
pip install --no-cache-dir "pydantic>=2.7.0,<3.0.0" -i "$MIRROR" --trusted-host "$HOST"

echo "安装 Pydantic Settings..."
pip install --no-cache-dir "pydantic-settings>=2.5.0,<3.0.0" -i "$MIRROR" --trusted-host "$HOST"

echo "安装 Starlette..."
pip install --no-cache-dir "starlette>=0.37.0" -i "$MIRROR" --trusted-host "$HOST"

echo "安装 FastAPI 0.115.14（固定版本）..."
pip install --no-cache-dir "fastapi==0.115.14" -i "$MIRROR" --trusted-host "$HOST"

echo "安装 Uvicorn 0.30+..."
pip install --no-cache-dir "uvicorn[standard]>=0.30.0,<0.31.0" -i "$MIRROR" --trusted-host "$HOST"

echo ""

# 验证版本
echo ">>> 验证版本..."
pip show fastapi uvicorn pydantic 2>/dev/null | grep -E "^Name|^Version"
echo ""

# 测试导入
echo ">>> 测试导入..."
cd backend
python3 -c "
import fastapi
import pydantic
print(f'FastAPI: {fastapi.__version__}')
print(f'Pydantic: {pydantic.__version__}')

# 检查版本
from packaging import version
if version.parse(fastapi.__version__) < version.parse('0.115.0'):
    raise Exception(f'FastAPI 版本过低: {fastapi.__version__}')
if version.parse(pydantic.__version__) < version.parse('2.7.0'):
    raise Exception(f'Pydantic 版本过低: {pydantic.__version__}')

from main import app
print('✓ 导入成功')
"

cd ..
deactivate

echo ""
echo "=========================================="
echo "✓ 修复完成！"
echo "=========================================="

