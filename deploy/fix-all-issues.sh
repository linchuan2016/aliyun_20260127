#!/bin/bash
# 完整修复所有问题（FastAPI版本 + 服务配置）
# 在服务器上执行: bash deploy/fix-all-issues.sh

set -e

echo "=========================================="
echo "完整修复所有问题"
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

# 2. 修复 systemd 服务配置路径
echo ">>> 2. 修复 systemd 服务配置..."
SERVICE_FILE="/etc/systemd/system/my-fullstack-app.service"

if [ -f "$SERVICE_FILE" ]; then
    # 备份原配置
    sudo cp "$SERVICE_FILE" "${SERVICE_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 检查并修复路径
    if grep -q "/venv/bin/uvicorn" "$SERVICE_FILE" || grep -q "ExecStart=.*uvicorn" "$SERVICE_FILE"; then
        echo "发现路径问题，正在修复..."
        
        # 创建正确的服务配置
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
        echo "✓ 服务配置已修复"
    else
        echo "✓ 服务配置路径正确"
    fi
else
    echo "创建服务配置..."
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

# 验证配置
echo ""
echo "当前服务配置："
cat "$SERVICE_FILE"
echo ""
echo ""

# 3. 升级 FastAPI 和相关依赖
echo ">>> 3. 升级 FastAPI 和相关依赖..."
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

# 4. 测试导入
echo ">>> 4. 测试模块导入..."
cd "$DEPLOY_PATH/backend"
source ../venv/bin/activate

python3 << 'TEST_EOF'
import sys
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
deactivate

if [ $TEST_RESULT -ne 0 ]; then
    echo ""
    echo "✗ 测试失败，请检查错误信息"
    exit 1
fi

echo ""

# 5. 验证 uvicorn 路径
echo ">>> 5. 验证 uvicorn 路径..."
UVICORN_PATH="$DEPLOY_PATH/venv/bin/uvicorn"
if [ -f "$UVICORN_PATH" ]; then
    echo "✓ uvicorn 路径存在: $UVICORN_PATH"
    $UVICORN_PATH --version
else
    echo "✗ uvicorn 路径不存在: $UVICORN_PATH"
    echo "查找 uvicorn..."
    find "$DEPLOY_PATH/venv" -name "uvicorn" 2>/dev/null || echo "未找到 uvicorn"
    exit 1
fi
echo ""

# 6. 重新加载systemd配置
echo ">>> 6. 重新加载systemd配置..."
sudo systemctl daemon-reload
echo "✓ 配置已重新加载"
echo ""

# 7. 启动服务
echo ">>> 7. 启动服务..."
sudo systemctl start my-fullstack-app
sleep 5
echo ""

# 8. 检查服务状态
echo ">>> 8. 检查服务状态..."
if sudo systemctl is-active --quiet my-fullstack-app; then
    echo "✓ 服务运行正常"
    sudo systemctl status my-fullstack-app --no-pager -l | head -15
else
    echo "✗ 服务启动失败"
    echo ""
    echo "查看错误日志："
    sudo journalctl -u my-fullstack-app -n 50 --no-pager
    echo ""
    echo "检查 ExecStart 路径："
    grep "ExecStart=" "$SERVICE_FILE"
    echo ""
    echo "检查 uvicorn 是否存在："
    ls -lh "$UVICORN_PATH" || echo "uvicorn 不存在"
    exit 1
fi
echo ""

# 9. 测试API
echo ">>> 9. 测试API..."
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
echo "✓ 所有问题已修复！服务正常运行"
echo "=========================================="
echo ""
echo "服务信息："
echo "  状态: $(sudo systemctl is-active my-fullstack-app)"
echo "  端口: 8000"
echo "  API: http://127.0.0.1:8000/api/health"
echo ""

