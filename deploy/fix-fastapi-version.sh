#!/bin/bash
# 修复 FastAPI 版本兼容性问题
# 在服务器上执行: bash deploy/fix-fastapi-version.sh

set -e

echo "=========================================="
echo "修复 FastAPI 版本兼容性问题"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 1. 停止服务
echo ">>> 停止服务..."
sudo systemctl stop my-fullstack-app 2>/dev/null || true
pkill -f "uvicorn main:app" 2>/dev/null || true
sleep 2
echo "✓ 服务已停止"
echo ""

# 2. 激活虚拟环境并升级依赖
echo ">>> 升级 FastAPI 和相关依赖..."
cd "$DEPLOY_PATH"
source venv/bin/activate

# 显示当前版本
echo "当前版本："
pip show fastapi pydantic uvicorn 2>/dev/null | grep -E "^Name|^Version" || echo "未安装"
echo ""

# 升级 pip
echo "升级 pip..."
pip install --upgrade pip --quiet
echo "✓ pip 已升级"
echo ""

# 卸载旧版本（避免冲突）
echo "卸载旧版本..."
pip uninstall -y fastapi pydantic pydantic-settings uvicorn 2>/dev/null || true
echo "✓ 旧版本已卸载"
echo ""

# 安装兼容版本
echo "安装兼容版本..."
pip install "fastapi>=0.109.0,<0.110.0" --quiet
pip install "uvicorn[standard]>=0.27.0,<0.28.0" --quiet
pip install "pydantic>=2.5.0,<3.0.0" --quiet
pip install "pydantic-settings>=2.1.0,<3.0.0" --quiet
echo "✓ 新版本已安装"
echo ""

# 安装其他依赖
echo "安装其他依赖..."
cd backend
pip install -r requirements.txt --quiet
echo "✓ 所有依赖已安装"
echo ""

# 显示新版本
echo "新版本："
pip show fastapi pydantic uvicorn 2>/dev/null | grep -E "^Name|^Version"
echo ""

deactivate

# 3. 测试导入
echo ">>> 测试模块导入..."
cd "$DEPLOY_PATH/backend"
source ../venv/bin/activate

python3 << 'TEST_EOF'
try:
    import fastapi
    import pydantic
    from fastapi import Depends
    from fastapi.security import OAuth2PasswordRequestForm
    print(f"✓ FastAPI {fastapi.__version__} 导入成功")
    print(f"✓ Pydantic {pydantic.__version__} 导入成功")
    
    # 测试 Depends 是否正常工作
    from fastapi.dependencies.utils import get_dependant
    print("✓ Depends 工具函数可用")
    
    # 测试是否可以导入应用
    from main import app
    print("✓ 应用模块导入成功")
    print("✓ 所有测试通过！")
except Exception as e:
    print(f"✗ 导入失败: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
TEST_EOF

if [ $? -ne 0 ]; then
    echo ""
    echo "✗ 测试失败，请检查错误信息"
    exit 1
fi

deactivate
echo ""

# 4. 重新加载systemd配置
echo ">>> 重新加载systemd配置..."
sudo systemctl daemon-reload
echo "✓ 配置已重新加载"
echo ""

# 5. 启动服务
echo ">>> 启动服务..."
sudo systemctl start my-fullstack-app
sleep 5
echo ""

# 6. 检查服务状态
echo ">>> 检查服务状态..."
if sudo systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务运行正常"
    sudo systemctl status my-fullstack-app --no-pager -l | head -15
else
    echo "✗ 服务启动失败"
    echo ""
    echo "查看错误日志："
    sudo journalctl -u my-fullstack-app -n 50 --no-pager
    exit 1
fi
echo ""

# 7. 测试API
echo ">>> 测试API..."
sleep 2
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ API正常响应"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "✗ API无响应"
    echo "查看最新日志："
    sudo journalctl -u my-fullstack-app -n 30 --no-pager
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ 修复成功！服务正常运行"
echo "=========================================="

