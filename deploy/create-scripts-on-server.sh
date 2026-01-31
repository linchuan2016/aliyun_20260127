#!/bin/bash
# 在服务器上直接创建所有需要的脚本
# 在服务器上执行: bash deploy/create-scripts-on-server.sh

echo "=========================================="
echo "在服务器上创建部署脚本"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"
cd "$DEPLOY_PATH/deploy" || mkdir -p "$DEPLOY_PATH/deploy" && cd "$DEPLOY_PATH/deploy"

echo "创建脚本目录: $DEPLOY_PATH/deploy"
echo ""

# 创建 force-install-correct-versions.sh
cat > force-install-correct-versions.sh << 'SCRIPT_EOF'
#!/bin/bash
# 强制安装正确版本（防止回退）
set -e

DEPLOY_PATH="/var/www/my-fullstack-app"
MIRROR="https://mirrors.aliyun.com/pypi/simple/"
HOST="mirrors.aliyun.com"

cd "$DEPLOY_PATH"
source venv/bin/activate

echo ">>> 完全卸载并重新安装..."
pip uninstall -y fastapi uvicorn starlette pydantic pydantic-settings pydantic-core 2>/dev/null || true
sleep 1

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
echo "验证版本..."
pip show fastapi uvicorn pydantic | grep -E "^Name|^Version"

cd backend
python3 -c "
import fastapi
import pydantic
print(f'FastAPI: {fastapi.__version__}')
print(f'Pydantic: {pydantic.__version__}')
from packaging import version
if version.parse(fastapi.__version__) < version.parse('0.115.0'):
    raise Exception(f'FastAPI 版本过低')
from main import app
print('✓ 导入成功')
"

cd ..
deactivate
echo "✓ 安装完成！"
SCRIPT_EOF

chmod +x force-install-correct-versions.sh
echo "✓ 创建 force-install-correct-versions.sh"

# 创建 fix-version-downgrade.sh
cat > fix-version-downgrade.sh << 'SCRIPT_EOF'
#!/bin/bash
# 修复版本回退问题
set -e

DEPLOY_PATH="/var/www/my-fullstack-app"
MIRROR="https://mirrors.aliyun.com/pypi/simple/"
HOST="mirrors.aliyun.com"

cd "$DEPLOY_PATH"
source venv/bin/activate

pip uninstall -y fastapi uvicorn starlette pydantic pydantic-settings 2>/dev/null || true
sleep 1

pip install --no-cache-dir "pydantic>=2.7.0,<3.0.0" -i "$MIRROR" --trusted-host "$HOST"
pip install --no-cache-dir "pydantic-settings>=2.5.0,<3.0.0" -i "$MIRROR" --trusted-host "$HOST"
pip install --no-cache-dir "starlette>=0.37.0" -i "$MIRROR" --trusted-host "$HOST"
pip install --no-cache-dir "fastapi==0.115.14" -i "$MIRROR" --trusted-host "$HOST"
pip install --no-cache-dir "uvicorn[standard]>=0.30.0,<0.31.0" -i "$MIRROR" --trusted-host "$HOST"

pip show fastapi uvicorn pydantic | grep -E "^Name|^Version"

cd backend
python3 -c "from main import app; print('✓ 导入成功')"
cd ..

deactivate
echo "✓ 修复完成！"
SCRIPT_EOF

chmod +x fix-version-downgrade.sh
echo "✓ 创建 fix-version-downgrade.sh"

echo ""
echo "=========================================="
echo "✓ 脚本创建完成！"
echo "=========================================="
echo ""
echo "现在可以执行："
echo "  bash deploy/force-install-correct-versions.sh"
echo ""

