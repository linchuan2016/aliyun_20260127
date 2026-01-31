#!/bin/bash
# 完整启动服务流程
# 在服务器上执行: bash deploy/start-service-complete.sh

set -e

echo "=========================================="
echo "启动后端服务（完整流程）"
echo "=========================================="
echo ""

DEPLOY_PATH="/var/www/my-fullstack-app"
cd "$DEPLOY_PATH"

# 1. 检查虚拟环境
echo ">>> 1. 检查虚拟环境..."
if [ ! -d "venv" ]; then
    echo "✗ 虚拟环境不存在，请先创建"
    exit 1
fi

source venv/bin/activate

# 检查关键依赖
echo "检查关键依赖..."
python3 -c "
import fastapi
import pydantic
import uvicorn
print(f'✓ FastAPI {fastapi.__version__}')
print(f'✓ Pydantic {pydantic.__version__}')
print(f'✓ Uvicorn {uvicorn.__version__}')
" 2>/dev/null || {
    echo "✗ 依赖未安装完整，请先执行安装脚本"
    deactivate
    exit 1
}

deactivate
echo "✓ 虚拟环境正常"
echo ""

# 2. 检查服务配置
echo ">>> 2. 检查 systemd 服务配置..."
SERVICE_FILE="/etc/systemd/system/my-fullstack-app.service"
if [ ! -f "$SERVICE_FILE" ]; then
    echo "✗ 服务配置文件不存在，正在创建..."
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
else
    echo "✓ 服务配置文件存在"
fi
echo ""

# 3. 重新加载 systemd
echo ">>> 3. 重新加载 systemd 配置..."
sudo systemctl daemon-reload
echo "✓ 配置已重新加载"
echo ""

# 4. 停止旧服务（如果有）
echo ">>> 4. 停止旧服务..."
sudo systemctl stop my-fullstack-app 2>/dev/null || true
pkill -f "uvicorn main:app" 2>/dev/null || true
sleep 2
echo "✓ 旧服务已停止"
echo ""

# 5. 测试应用是否可以导入
echo ">>> 5. 测试应用导入..."
cd backend
source ../venv/bin/activate

python3 << 'TEST_EOF'
import sys
try:
    from main import app
    print("✓ 应用模块导入成功")
    sys.exit(0)
except Exception as e:
    print(f"✗ 应用导入失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
TEST_EOF

if [ $? -ne 0 ]; then
    echo "✗ 应用导入失败，请检查错误信息"
    deactivate
    exit 1
fi

deactivate
cd ..
echo ""

# 6. 启动服务
echo ">>> 6. 启动服务..."
sudo systemctl start my-fullstack-app
sleep 5
echo ""

# 7. 检查服务状态
echo ">>> 7. 检查服务状态..."
if sudo systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务运行正常"
    sudo systemctl status my-fullstack-app --no-pager -l | head -20
else
    echo "✗ 服务启动失败"
    echo ""
    echo "查看错误日志："
    sudo journalctl -u my-fullstack-app -n 50 --no-pager
    exit 1
fi
echo ""

# 8. 等待服务完全启动
echo ">>> 8. 等待服务完全启动..."
for i in {1..10}; do
    if curl -s http://127.0.0.1:8000/api/health > /dev/null 2>&1; then
        echo "✓ 服务已就绪（尝试 $i 次）"
        break
    else
        if [ $i -eq 10 ]; then
            echo "✗ 服务启动超时"
            echo "查看最新日志："
            sudo journalctl -u my-fullstack-app -n 30 --no-pager
            exit 1
        fi
        echo "等待服务启动... ($i/10)"
        sleep 2
    fi
done
echo ""

# 9. 测试 API
echo ">>> 9. 测试 API..."
if curl -s http://127.0.0.1:8000/api/health > /dev/null; then
    echo "✓ API 正常响应"
    curl -s http://127.0.0.1:8000/api/health
    echo ""
else
    echo "✗ API 无响应"
    echo "查看最新日志："
    sudo journalctl -u my-fullstack-app -n 30 --no-pager
    exit 1
fi
echo ""

# 10. 检查端口监听
echo ">>> 10. 检查端口监听..."
if netstat -tlnp 2>/dev/null | grep :8000 > /dev/null || ss -tlnp 2>/dev/null | grep :8000 > /dev/null; then
    echo "✓ 端口 8000 正在监听"
    netstat -tlnp 2>/dev/null | grep :8000 || ss -tlnp 2>/dev/null | grep :8000
else
    echo "⚠ 端口 8000 未监听"
fi
echo ""

echo "=========================================="
echo "✓ 服务启动成功！"
echo "=========================================="
echo ""
echo "服务信息："
echo "  状态: $(sudo systemctl is-active my-fullstack-app)"
echo "  端口: 8000"
echo "  本地 API: http://127.0.0.1:8000/api/health"
echo "  外部访问: http://47.112.29.212/api/health"
echo ""
echo "常用命令："
echo "  查看状态: sudo systemctl status my-fullstack-app"
echo "  查看日志: sudo journalctl -u my-fullstack-app -f"
echo "  重启服务: sudo systemctl restart my-fullstack-app"
echo "  停止服务: sudo systemctl stop my-fullstack-app"
echo ""

