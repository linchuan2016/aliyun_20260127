#!/bin/bash
# 升级依赖并启动服务（一键完成）
# 在服务器上执行: bash deploy/upgrade-and-start.sh

set -e

echo "=========================================="
echo "升级依赖并启动服务"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"
MIRROR="https://mirrors.aliyun.com/pypi/simple/"
HOST="mirrors.aliyun.com"

cd "$DEPLOY_PATH"

# 1. 检查当前版本
echo ">>> 1. 检查当前版本..."
source venv/bin/activate
pip show fastapi uvicorn pydantic 2>/dev/null | grep -E "^Name|^Version" || echo "未安装"
deactivate
echo ""

# 2. 完全卸载旧版本
echo ">>> 2. 卸载旧版本..."
source venv/bin/activate
pip uninstall -y fastapi uvicorn starlette pydantic pydantic-settings pydantic-core 2>/dev/null || true
deactivate
sleep 1
echo "✓ 已卸载"
echo ""

# 3. 安装正确版本（使用国内镜像）
echo ">>> 3. 安装正确版本（使用国内镜像）..."
source venv/bin/activate

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
echo ""

# 4. 测试导入
echo ">>> 4. 测试应用导入..."
cd backend
python3 << 'TEST_EOF'
import sys
try:
    import fastapi
    import pydantic
    print(f"FastAPI: {fastapi.__version__}")
    print(f"Pydantic: {pydantic.__version__}")
    
    from packaging import version
    if version.parse(fastapi.__version__) < version.parse("0.115.0"):
        raise Exception(f"FastAPI 版本过低: {fastapi.__version__}")
    
    from main import app
    print("✓ 应用导入成功")
    sys.exit(0)
except Exception as e:
    print(f"✗ 导入失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
TEST_EOF

if [ $? -ne 0 ]; then
    echo "✗ 导入测试失败"
    deactivate
    exit 1
fi

cd ..
deactivate
echo ""

# 5. 重新加载 systemd
echo ">>> 5. 重新加载 systemd..."
sudo systemctl daemon-reload
echo "✓ 已重新加载"
echo ""

# 6. 启动服务
echo ">>> 6. 启动服务..."
sudo systemctl stop my-fullstack-app 2>/dev/null || true
pkill -f "uvicorn main:app" 2>/dev/null || true
sleep 2

sudo systemctl start my-fullstack-app
sleep 5
echo ""

# 7. 检查服务状态
echo ">>> 7. 检查服务状态..."
if sudo systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务运行正常"
    sudo systemctl status my-fullstack-app --no-pager -l | head -15
else
    echo "✗ 服务启动失败"
    echo "查看错误日志："
    sudo journalctl -u my-fullstack-app -n 50 --no-pager
    exit 1
fi
echo ""

# 8. 测试 API
echo ">>> 8. 测试 API..."
sleep 3
for i in {1..5}; do
    if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
        echo "✓ API 正常响应"
        curl -s http://127.0.0.1:8000/api/health
        echo ""
        break
    else
        if [ $i -eq 5 ]; then
            echo "✗ API 无响应"
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
echo "✓ 升级并启动完成！"
echo "=========================================="
echo ""
echo "服务信息："
echo "  状态: $(sudo systemctl is-active my-fullstack-app)"
echo "  API: http://127.0.0.1:8000/api/health"
echo ""

