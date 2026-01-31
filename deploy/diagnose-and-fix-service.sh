#!/bin/bash
# 诊断并修复服务问题（针对Python升级后）
# 在服务器上执行: bash deploy/diagnose-and-fix-service.sh

set -e

echo "=========================================="
echo "诊断并修复后端服务问题"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"

# 1. 检查服务状态
echo ">>> 1. 检查服务状态..."
if sudo systemctl is-active --quiet my-fullstack-app 2>/dev/null; then
    echo "✓ 服务正在运行"
    sudo systemctl status my-fullstack-app --no-pager -l | head -10
else
    echo "✗ 服务未运行"
fi
echo ""

# 2. 检查端口监听
echo ">>> 2. 检查端口8000监听..."
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "✓ 端口8000正在监听"
    netstat -tlnp 2>/dev/null | grep :8000 || ss -tlnp 2>/dev/null | grep :8000
else
    echo "✗ 端口8000未监听"
fi
echo ""

# 3. 检查虚拟环境Python版本
echo ">>> 3. 检查虚拟环境Python版本..."
if [ -f "$DEPLOY_PATH/venv/bin/python" ]; then
    VENV_PYTHON_VERSION=$($DEPLOY_PATH/venv/bin/python --version 2>&1)
    echo "虚拟环境 Python: $VENV_PYTHON_VERSION"
    
    # 检查是否是Python 3.10
    if echo "$VENV_PYTHON_VERSION" | grep -q "3.10"; then
        echo "✓ 虚拟环境使用 Python 3.10"
    else
        echo "⚠ 虚拟环境不是 Python 3.10，可能需要重建"
    fi
else
    echo "✗ 虚拟环境不存在"
fi
echo ""

# 4. 检查systemd服务配置中的Python路径
echo ">>> 4. 检查systemd服务配置..."
SERVICE_FILE="/etc/systemd/system/my-fullstack-app.service"
if [ -f "$SERVICE_FILE" ]; then
    echo "服务文件内容："
    cat "$SERVICE_FILE"
    echo ""
    
    # 检查ExecStart路径
    EXEC_START=$(grep "^ExecStart=" "$SERVICE_FILE" | cut -d'=' -f2-)
    echo "ExecStart: $EXEC_START"
    
    # 检查uvicorn是否存在
    UVICORN_PATH=$(echo "$EXEC_START" | awk '{print $1}')
    if [ -f "$UVICORN_PATH" ]; then
        echo "✓ uvicorn 路径存在: $UVICORN_PATH"
    else
        echo "✗ uvicorn 路径不存在: $UVICORN_PATH"
        echo "  需要更新服务配置"
    fi
else
    echo "✗ 服务文件不存在: $SERVICE_FILE"
fi
echo ""

# 5. 查看服务日志
echo ">>> 5. 查看服务最近日志（最后30行）..."
sudo journalctl -u my-fullstack-app -n 30 --no-pager || echo "无法读取日志"
echo ""

# 6. 检查虚拟环境中的依赖
echo ">>> 6. 检查虚拟环境依赖..."
if [ -f "$DEPLOY_PATH/venv/bin/python" ]; then
    cd "$DEPLOY_PATH"
    source venv/bin/activate
    
    echo "检查关键依赖..."
    python -c "import uvicorn; print(f'✓ uvicorn: {uvicorn.__version__}')" 2>/dev/null || echo "✗ uvicorn 未安装"
    python -c "import fastapi; print(f'✓ fastapi: {fastapi.__version__}')" 2>/dev/null || echo "✗ fastapi 未安装"
    python -c "from database import SessionLocal; print('✓ database 模块正常')" 2>/dev/null || echo "✗ database 模块有问题"
    
    deactivate
else
    echo "✗ 虚拟环境不存在，无法检查"
fi
echo ""

# 7. 尝试手动启动测试
echo ">>> 7. 尝试手动启动测试..."
cd "$DEPLOY_PATH/backend"

# 停止服务
sudo systemctl stop my-fullstack-app 2>/dev/null || true
sleep 2

# 清理残留进程
pkill -f "uvicorn main:app" 2>/dev/null || true
sleep 1

# 检查是否可以手动启动
if [ -f "$DEPLOY_PATH/venv/bin/uvicorn" ]; then
    echo "测试手动启动（后台运行5秒）..."
    cd "$DEPLOY_PATH/backend"
    source ../venv/bin/activate
    
    # 后台启动测试
    timeout 5 $DEPLOY_PATH/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000 > /tmp/uvicorn-test.log 2>&1 &
    UVICORN_PID=$!
    sleep 3
    
    # 测试连接
    if curl -s http://127.0.0.1:8000/api/health > /dev/null 2>&1; then
        echo "✓ 手动启动成功，API可以访问"
        curl -s http://127.0.0.1:8000/api/health
        echo ""
    else
        echo "✗ 手动启动失败，查看日志："
        cat /tmp/uvicorn-test.log
    fi
    
    # 停止测试进程
    kill $UVICORN_PID 2>/dev/null || true
    pkill -f "uvicorn main:app" 2>/dev/null || true
    sleep 1
    
    deactivate
else
    echo "✗ uvicorn 不存在，无法测试"
fi
echo ""

# 8. 修复建议
echo "=========================================="
echo "诊断完成，修复建议："
echo "=========================================="
echo ""

# 检查是否需要重建虚拟环境
if [ -f "$DEPLOY_PATH/venv/bin/python" ]; then
    VENV_VERSION=$($DEPLOY_PATH/venv/bin/python --version 2>&1)
    if ! echo "$VENV_VERSION" | grep -q "3.10"; then
        echo "⚠ 建议重建虚拟环境（使用 Python 3.10）："
        echo "  cd $DEPLOY_PATH"
        echo "  mv venv venv.backup.\$(date +%Y%m%d_%H%M%S)"
        echo "  /usr/local/bin/python3.10 -m venv venv"
        echo "  source venv/bin/activate"
        echo "  pip install --upgrade pip"
        echo "  cd backend"
        echo "  pip install -r requirements.txt"
        echo ""
    fi
fi

# 检查服务配置
if [ -f "$SERVICE_FILE" ]; then
    EXEC_START=$(grep "^ExecStart=" "$SERVICE_FILE" | cut -d'=' -f2- | awk '{print $1}')
    if [ ! -f "$EXEC_START" ]; then
        echo "⚠ 需要更新服务配置中的 uvicorn 路径"
        echo "  当前路径不存在: $EXEC_START"
        echo "  应该使用: $DEPLOY_PATH/venv/bin/uvicorn"
        echo ""
    fi
fi

echo "执行修复..."
echo ""

# 9. 自动修复
echo ">>> 9. 开始自动修复..."

# 9.1 更新服务配置
if [ -f "$SERVICE_FILE" ]; then
    echo "更新服务配置..."
    sudo sed -i "s|ExecStart=.*uvicorn|ExecStart=$DEPLOY_PATH/venv/bin/uvicorn|g" "$SERVICE_FILE"
    sudo sed -i "s|Environment=\"PATH=.*\"|Environment=\"PATH=$DEPLOY_PATH/venv/bin\"|g" "$SERVICE_FILE"
    echo "✓ 服务配置已更新"
fi

# 9.2 重新加载systemd
echo "重新加载systemd配置..."
sudo systemctl daemon-reload
echo "✓ 配置已重新加载"
echo ""

# 9.3 启动服务
echo "启动服务..."
sudo systemctl start my-fullstack-app
sleep 5

# 9.4 检查服务状态
echo "检查服务状态..."
if sudo systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务启动成功"
    sudo systemctl status my-fullstack-app --no-pager -l | head -15
else
    echo "✗ 服务启动失败，查看详细日志："
    sudo journalctl -u my-fullstack-app -n 50 --no-pager
fi
echo ""

# 9.5 测试API
echo "测试API..."
sleep 2
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ API正常响应"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "✗ API无响应"
    echo "查看最新日志："
    sudo journalctl -u my-fullstack-app -n 30 --no-pager
fi

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="

