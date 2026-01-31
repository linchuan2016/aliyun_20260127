#!/bin/bash
# 修复版本冲突问题
# 在服务器上执行: bash deploy/fix-version-conflict.sh

set -e

echo "=========================================="
echo "修复版本冲突问题"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 1. 停止服务
echo ">>> 1. 停止服务..."
sudo systemctl stop my-fullstack-app 2>/dev/null || true
pkill -f "uvicorn main:app" 2>/dev/null || true
sleep 2
echo "✓ 服务已停止"
echo ""

# 2. 激活虚拟环境
cd "$DEPLOY_PATH"
source venv/bin/activate

# 3. 显示当前版本
echo ">>> 2. 当前版本："
pip show fastapi pydantic pydantic-settings uvicorn 2>/dev/null | grep -E "^Name|^Version" || echo "未安装"
echo ""

# 4. 完全卸载相关包
echo ">>> 3. 完全卸载旧版本..."
pip uninstall -y fastapi pydantic pydantic-settings pydantic-core uvicorn starlette 2>/dev/null || true
echo "✓ 旧版本已卸载"
echo ""

# 5. 配置 pip 使用国内镜像（加速）
echo ">>> 4. 配置 pip 使用国内镜像源..."
MIRROR="https://mirrors.aliyun.com/pypi/simple/"
TRUSTED_HOST="mirrors.aliyun.com"

# 创建虚拟环境的 pip 配置
mkdir -p "$DEPLOY_PATH/venv/pip"
tee "$DEPLOY_PATH/venv/pip/pip.conf" > /dev/null << EOF
[global]
index-url = $MIRROR
trusted-host = $TRUSTED_HOST
timeout = 120

[install]
trusted-host = $TRUSTED_HOST
EOF
echo "✓ pip 镜像源已配置（阿里云）"
echo ""

# 6. 升级 pip
echo ">>> 5. 升级 pip..."
pip install --upgrade pip -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --quiet
echo "✓ pip 已升级"
echo ""

# 7. 按正确顺序安装（先安装 pydantic，再安装依赖它的包）
echo ">>> 6. 安装兼容版本（按正确顺序，使用国内镜像）..."

# 先安装 pydantic（确保版本 >= 2.7.0，满足 pydantic-settings 要求）
echo "安装 Pydantic 2.7+..."
pip install "pydantic>=2.7.0,<3.0.0" -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir --quiet
echo "✓ Pydantic 已安装"

# 再安装 pydantic-settings（现在 pydantic 版本满足要求）
echo "安装 Pydantic Settings..."
pip install "pydantic-settings>=2.5.0,<3.0.0" -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir --quiet
echo "✓ Pydantic Settings 已安装"

# 安装 FastAPI（依赖 pydantic）
echo "安装 FastAPI 0.115+..."
pip install "fastapi>=0.115.0,<0.116.0" -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir --quiet
echo "✓ FastAPI 已安装"

# 安装 Uvicorn
echo "安装 Uvicorn 0.30+..."
pip install "uvicorn[standard]>=0.30.0,<0.31.0" -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir --quiet
echo "✓ Uvicorn 已安装"
echo ""

# 8. 安装其他依赖
echo ">>> 7. 安装其他依赖..."
cd backend
pip install -r requirements.txt -i "$MIRROR" --trusted-host "$TRUSTED_HOST" --no-cache-dir --quiet
cd ..
echo "✓ 所有依赖已安装"
echo ""

# 8. 显示新版本
echo ">>> 7. 新版本："
pip show fastapi pydantic pydantic-settings uvicorn 2>/dev/null | grep -E "^Name|^Version"
echo ""

# 9. 检查版本冲突
echo ">>> 8. 检查版本冲突..."
CONFLICTS=$(pip check 2>&1 | grep -i conflict || echo "")
if [ -n "$CONFLICTS" ]; then
    echo "⚠ 发现版本冲突："
    echo "$CONFLICTS"
    echo ""
    echo "尝试修复..."
    pip install --upgrade --force-reinstall pydantic pydantic-settings --no-cache-dir --quiet
    echo "✓ 已尝试修复"
else
    echo "✓ 无版本冲突"
fi
echo ""

# 10. 测试导入（在正确的目录下）
echo ">>> 9. 测试模块导入..."
cd backend  # 重要：必须在 backend 目录下
python3 << 'TEST_EOF'
import sys
import os

# 确保在正确的目录
if not os.path.exists('main.py'):
    print(f"✗ 错误：当前目录 {os.getcwd()} 中没有 main.py")
    print("请在 backend 目录下执行")
    sys.exit(1)

try:
    import fastapi
    import pydantic
    from fastapi import Depends
    from fastapi.security import OAuth2PasswordRequestForm
    
    print(f"✓ FastAPI {fastapi.__version__} 导入成功")
    print(f"✓ Pydantic {pydantic.__version__} 导入成功")
    
    # 测试 Depends
    from fastapi.dependencies.utils import get_dependant
    print("✓ Depends 工具函数可用")
    
    # 测试是否可以导入应用（必须在 backend 目录下）
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

# 11. 重新加载systemd配置
echo ">>> 10. 重新加载systemd配置..."
sudo systemctl daemon-reload
echo "✓ 配置已重新加载"
echo ""

# 12. 启动服务
echo ">>> 11. 启动服务..."
sudo systemctl start my-fullstack-app
sleep 5
echo ""

# 13. 检查服务状态
echo ">>> 12. 检查服务状态..."
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

# 14. 测试API
echo ">>> 13. 测试API..."
sleep 3
for i in {1..5}; do
    if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
        echo "✓ API正常响应"
        curl -s http://127.0.0.1:8000/api/health
        echo ""
        break
    else
        if [ $i -eq 5 ]; then
            echo "✗ API无响应（尝试了5次）"
            echo "查看最新日志："
            sudo journalctl -u my-fullstack-app -n 30 --no-pager
            exit 1
        fi
        echo "等待服务启动... ($i/5)"
        sleep 2
    fi
done

echo ""
echo "=========================================="
echo "✓ 修复成功！服务正常运行"
echo "=========================================="
echo ""
echo "版本信息："
source venv/bin/activate
pip show fastapi pydantic pydantic-settings uvicorn 2>/dev/null | grep -E "^Name|^Version"
deactivate
echo ""

