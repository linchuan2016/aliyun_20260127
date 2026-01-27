#!/bin/bash
# 快速修复脚本
# 使用方法: sudo bash quick-fix.sh

set -e

echo "========================================"
echo "  快速修复后端服务"
echo "========================================"
echo ""

# 1. 停止服务
echo "[1/6] 停止服务..."
sudo systemctl stop my-fullstack-app 2>/dev/null || true

# 2. 检查虚拟环境
echo "[2/6] 检查虚拟环境..."
cd /var/www/my-fullstack-app/backend
if [ ! -f "../venv/bin/uvicorn" ]; then
    echo "  虚拟环境不完整，重新安装依赖..."
    source ../venv/bin/activate 2>/dev/null || python3 -m venv ../venv
    source ../venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
fi

# 3. 修复服务文件
echo "[3/6] 修复服务文件..."
sudo sed -i 's/YOUR_SERVER_IP/47.112.29.212/g' /etc/systemd/system/my-fullstack-app.service 2>/dev/null || true
sudo sed -i 's/User=www-data/User=root/' /etc/systemd/system/my-fullstack-app.service 2>/dev/null || true

# 4. 重新加载
echo "[4/6] 重新加载配置..."
sudo systemctl daemon-reload

# 5. 启动服务
echo "[5/6] 启动服务..."
sudo systemctl start my-fullstack-app
sleep 3

# 6. 验证
echo "[6/6] 验证服务..."
echo ""
if systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务启动成功！"
    echo ""
    echo "服务状态："
    sudo systemctl status my-fullstack-app --no-pager -l | head -10
    echo ""
    echo "测试 API:"
    API_RESPONSE=$(curl -s http://localhost:8000/api/data 2>/dev/null || echo "失败")
    echo "  $API_RESPONSE"
else
    echo "✗ 服务启动失败"
    echo ""
    echo "错误日志："
    sudo journalctl -u my-fullstack-app -n 30 --no-pager
fi

echo ""
echo "========================================"

