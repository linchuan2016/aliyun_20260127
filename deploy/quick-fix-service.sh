#!/bin/bash
# 快速修复服务问题（Python升级后）
# 在服务器上执行: bash deploy/quick-fix-service.sh

set -e

DEPLOY_PATH="/var/www/my-fullstack-app"

echo "=========================================="
echo "快速修复后端服务"
echo "=========================================="
echo ""

# 1. 停止服务
echo ">>> 停止服务..."
sudo systemctl stop my-fullstack-app 2>/dev/null || true
pkill -f "uvicorn main:app" 2>/dev/null || true
sleep 2
echo "✓ 服务已停止"
echo ""

# 2. 检查并更新服务配置
echo ">>> 更新服务配置..."
SERVICE_FILE="/etc/systemd/system/my-fullstack-app.service"

# 确保使用正确的虚拟环境路径
if [ -f "$SERVICE_FILE" ]; then
    # 更新ExecStart路径
    sudo sed -i "s|ExecStart=.*|ExecStart=$DEPLOY_PATH/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4|g" "$SERVICE_FILE"
    # 更新PATH环境变量
    sudo sed -i "s|Environment=\"PATH=.*\"|Environment=\"PATH=$DEPLOY_PATH/venv/bin\"|g" "$SERVICE_FILE"
    echo "✓ 服务配置已更新"
else
    echo "✗ 服务文件不存在，创建新配置..."
    sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=My Fullstack App Backend Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DEPLOY_PATH/backend
Environment="PATH=$DEPLOY_PATH/venv/bin"
Environment="HOST=0.0.0.0"
Environment="PORT=8000"
Environment="ALLOWED_ORIGINS=http://47.112.29.212 https://linchuan.tech http://linchuan.tech"
ExecStart=$DEPLOY_PATH/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    echo "✓ 服务配置已创建"
fi
echo ""

# 3. 检查虚拟环境
echo ">>> 检查虚拟环境..."
if [ ! -f "$DEPLOY_PATH/venv/bin/python" ]; then
    echo "✗ 虚拟环境不存在，需要创建"
    echo "请先执行："
    echo "  cd $DEPLOY_PATH"
    echo "  /usr/local/bin/python3.10 -m venv venv"
    echo "  source venv/bin/activate"
    echo "  pip install --upgrade pip"
    echo "  cd backend"
    echo "  pip install -r requirements.txt"
    exit 1
fi

# 检查Python版本
VENV_PYTHON=$($DEPLOY_PATH/venv/bin/python --version 2>&1)
echo "虚拟环境 Python: $VENV_PYTHON"

# 检查uvicorn
if [ ! -f "$DEPLOY_PATH/venv/bin/uvicorn" ]; then
    echo "✗ uvicorn 未安装，正在安装..."
    cd "$DEPLOY_PATH"
    source venv/bin/activate
    pip install uvicorn fastapi
    deactivate
    echo "✓ uvicorn 已安装"
fi
echo ""

# 4. 重新加载systemd
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
    echo ""
    echo "可能的原因："
    echo "  1. 虚拟环境中的依赖未安装完整"
    echo "  2. Python版本不匹配"
    echo "  3. 代码有错误"
    echo ""
    echo "建议执行完整诊断："
    echo "  bash deploy/diagnose-and-fix-service.sh"
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

