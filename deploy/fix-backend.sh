#!/bin/bash
# 后端服务修复脚本
# 使用方法: sudo bash fix-backend.sh

set -e

echo "========================================"
echo "  后端服务修复工具"
echo "========================================"
echo ""

SERVICE_NAME="my-fullstack-app"
APP_DIR="/var/www/my-fullstack-app"
BACKEND_DIR="$APP_DIR/backend"
VENV_DIR="$APP_DIR/venv"
SERVER_IP="47.112.29.212"

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then 
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 1. 停止服务
echo "[1/7] 停止服务..."
systemctl stop $SERVICE_NAME 2>/dev/null || true

# 2. 检查虚拟环境
echo "[2/7] 检查虚拟环境..."
if [ ! -d "$VENV_DIR" ]; then
    echo "  虚拟环境不存在，正在创建..."
    cd $BACKEND_DIR
    python3 -m venv ../venv
    source ../venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "  ✓ 虚拟环境创建完成"
elif [ ! -f "$VENV_DIR/bin/uvicorn" ]; then
    echo "  uvicorn 未安装，正在安装..."
    cd $BACKEND_DIR
    source ../venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "  ✓ 依赖安装完成"
else
    echo "  ✓ 虚拟环境存在"
fi

# 3. 验证依赖
echo "[3/7] 验证依赖..."
cd $BACKEND_DIR
source ../venv/bin/activate
if ! python -c "import fastapi" 2>/dev/null; then
    echo "  fastapi 未安装，正在安装..."
    pip install -r requirements.txt
fi
if ! python -c "import uvicorn" 2>/dev/null; then
    echo "  uvicorn 未安装，正在安装..."
    pip install -r requirements.txt
fi
echo "  ✓ 依赖验证完成"

# 4. 测试手动运行
echo "[4/7] 测试手动运行..."
cd $BACKEND_DIR
source ../venv/bin/activate
timeout 3 python main.py > /tmp/backend-test.log 2>&1 &
TEST_PID=$!
sleep 2
if kill -0 $TEST_PID 2>/dev/null; then
    kill $TEST_PID 2>/dev/null || true
    echo "  ✓ 手动运行测试通过"
else
    echo "  ⚠️  手动运行测试失败，查看日志："
    cat /tmp/backend-test.log
fi

# 5. 修复服务文件
echo "[5/7] 修复服务文件..."
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# 备份原文件
cp $SERVICE_FILE ${SERVICE_FILE}.bak 2>/dev/null || true

# 修复 User
sed -i 's/User=www-data/User=root/' $SERVICE_FILE 2>/dev/null || true

# 修复 ALLOWED_ORIGINS
sed -i "s|ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=http://$SERVER_IP,https://$SERVER_IP|" $SERVICE_FILE 2>/dev/null || true

# 确保路径正确
sed -i "s|WorkingDirectory=.*|WorkingDirectory=$BACKEND_DIR|" $SERVICE_FILE 2>/dev/null || true
sed -i "s|Environment=\"PATH=.*|Environment=\"PATH=$VENV_DIR/bin\"|" $SERVICE_FILE 2>/dev/null || true
sed -i "s|ExecStart=.*|ExecStart=$VENV_DIR/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4|" $SERVICE_FILE 2>/dev/null || true

echo "  ✓ 服务文件已修复"

# 6. 重新加载并启动
echo "[6/7] 重新加载服务..."
systemctl daemon-reload

echo "[7/7] 启动服务..."
systemctl start $SERVICE_NAME
sleep 3

# 检查状态
echo ""
echo "========================================"
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "  ✓ 服务启动成功！"
    echo "========================================"
    echo ""
    systemctl status $SERVICE_NAME --no-pager -l | head -15
    echo ""
    echo "测试 API:"
    sleep 1
    curl -s http://localhost:8000/api/data || echo "  API 测试失败"
    echo ""
else
    echo "  ✗ 服务启动失败"
    echo "========================================"
    echo ""
    echo "服务状态："
    systemctl status $SERVICE_NAME --no-pager -l | head -20
    echo ""
    echo "最近日志："
    journalctl -u $SERVICE_NAME -n 30 --no-pager
    echo ""
    echo "请检查以上错误信息"
fi

