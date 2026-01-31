#!/bin/bash
# 强制安装正确版本（防止回退）
# 在服务器上执行: bash deploy/force-install-correct-versions.sh

set -e

echo "=========================================="
echo "强制安装正确版本（防止回退）"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"
MIRROR="https://mirrors.aliyun.com/pypi/simple/"
HOST="mirrors.aliyun.com"

cd "$DEPLOY_PATH"
source venv/bin/activate

# 1. 完全卸载所有相关包
echo ">>> 1. 完全卸载所有相关包..."
pip uninstall -y fastapi uvicorn starlette pydantic pydantic-settings pydantic-core 2>/dev/null || true
echo "✓ 已卸载"
echo ""

# 2. 升级 pip
echo ">>> 2. 升级 pip..."
pip install --upgrade pip -i "$MIRROR" --trusted-host "$HOST" --quiet
echo "✓ pip 已升级"
echo ""

# 3. 先安装其他依赖（不包含 fastapi/uvicorn）
echo ">>> 3. 安装其他依赖（不包含 fastapi/uvicorn）..."
cd backend

# 创建临时 requirements 文件（排除核心框架）
grep -v "^fastapi\|^uvicorn\|^pydantic\|^pydantic-settings" requirements.txt > /tmp/requirements-other.txt || true

if [ -s /tmp/requirements-other.txt ]; then
    pip install -r /tmp/requirements-other.txt -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir
    echo "✓ 其他依赖已安装"
else
    echo "⚠ 没有其他依赖需要安装"
fi
echo ""

# 4. 强制安装核心框架（使用 --force-reinstall 和 --no-deps 然后安装依赖）
echo ">>> 4. 强制安装核心框架（按正确顺序）..."

# 先安装 pydantic（基础）
echo "安装 Pydantic 2.7+..."
pip install --force-reinstall --no-deps "pydantic>=2.7.0,<3.0.0" -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir
pip install "pydantic-core>=2.18.0" -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir 2>/dev/null || true
echo "✓ Pydantic 已安装"

# 再安装 pydantic-settings
echo "安装 Pydantic Settings..."
pip install --force-reinstall --no-deps "pydantic-settings>=2.5.0,<3.0.0" -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir
pip install "pydantic>=2.7.0,<3.0.0" -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir 2>/dev/null || true
echo "✓ Pydantic Settings 已安装"

# 安装 starlette（FastAPI 的依赖）
echo "安装 Starlette..."
pip install --force-reinstall "starlette>=0.37.0" -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir
echo "✓ Starlette 已安装"

# 安装 FastAPI（强制版本）
echo "安装 FastAPI 0.115+..."
pip install --force-reinstall --no-deps "fastapi==0.115.14" -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir
# 确保依赖也安装
pip install "starlette>=0.37.0" "pydantic>=2.7.0,<3.0.0" -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir 2>/dev/null || true
echo "✓ FastAPI 已安装"

# 安装 Uvicorn
echo "安装 Uvicorn 0.30+..."
pip install --force-reinstall "uvicorn[standard]>=0.30.0,<0.31.0" -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir
echo "✓ Uvicorn 已安装"
echo ""

# 5. 验证版本
echo ">>> 5. 验证安装的版本..."
echo "FastAPI:"
pip show fastapi | grep "^Version" || echo "未安装"
echo "Pydantic:"
pip show pydantic | grep "^Version" || echo "未安装"
echo "Uvicorn:"
pip show uvicorn | grep "^Version" || echo "未安装"
echo ""

# 6. 检查是否有冲突
echo ">>> 6. 检查版本冲突..."
CONFLICTS=$(pip check 2>&1 | grep -i conflict || echo "")
if [ -n "$CONFLICTS" ]; then
    echo "⚠ 发现冲突："
    echo "$CONFLICTS"
    echo ""
    echo "尝试修复..."
    pip install --upgrade --force-reinstall pydantic pydantic-settings fastapi -i "$MIRROR" --trusted-host "$HOST" --no-cache-dir
else
    echo "✓ 无版本冲突"
fi
echo ""

# 7. 测试导入
echo ">>> 7. 测试导入..."
python3 << 'TEST_EOF'
import sys
try:
    import fastapi
    import pydantic
    print(f"✓ FastAPI {fastapi.__version__}")
    print(f"✓ Pydantic {pydantic.__version__}")
    
    # 检查版本
    from packaging import version
    if version.parse(fastapi.__version__) < version.parse("0.115.0"):
        print(f"✗ FastAPI 版本过低: {fastapi.__version__}")
        sys.exit(1)
    if version.parse(pydantic.__version__) < version.parse("2.7.0"):
        print(f"✗ Pydantic 版本过低: {pydantic.__version__}")
        sys.exit(1)
    
    # 测试导入应用
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

if [ $TEST_RESULT -ne 0 ]; then
    echo ""
    echo "✗ 测试失败"
    deactivate
    exit 1
fi

cd ..
deactivate

echo ""
echo "=========================================="
echo "✓ 安装完成！版本已确认"
echo "=========================================="
echo ""

