#!/bin/bash
# 强制升级 FastAPI 和 Pydantic（彻底解决兼容性问题）
# 在服务器上执行: bash deploy/force-upgrade-fastapi.sh

set -e

echo "=========================================="
echo "强制升级 FastAPI 和 Pydantic"
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
pip show fastapi pydantic uvicorn 2>/dev/null | grep -E "^Name|^Version" || echo "未安装"
echo ""

# 4. 完全卸载相关包（包括依赖）
echo ">>> 3. 完全卸载旧版本..."
pip freeze | grep -E "fastapi|pydantic|starlette" | xargs pip uninstall -y 2>/dev/null || true
pip uninstall -y fastapi pydantic pydantic-settings pydantic-core uvicorn starlette 2>/dev/null || true
echo "✓ 旧版本已完全卸载"
echo ""

# 5. 清理 pip 缓存
echo ">>> 4. 清理 pip 缓存..."
pip cache purge 2>/dev/null || true
echo "✓ 缓存已清理"
echo ""

# 6. 升级 pip
echo ">>> 5. 升级 pip..."
pip install --upgrade pip --quiet
echo "✓ pip 已升级"
echo ""

# 7. 安装最新兼容版本
echo ">>> 6. 安装最新兼容版本..."
echo "安装 FastAPI 0.115+ (支持 Pydantic 2.8+)..."
pip install "fastapi>=0.115.0,<0.116.0" --no-cache-dir --quiet
echo "✓ FastAPI 已安装"

echo "安装 Pydantic 2.8+..."
pip install "pydantic>=2.8.0,<3.0.0" --no-cache-dir --quiet
pip install "pydantic-settings>=2.5.0,<3.0.0" --no-cache-dir --quiet
echo "✓ Pydantic 已安装"

echo "安装 Uvicorn 0.30+..."
pip install "uvicorn[standard]>=0.30.0,<0.31.0" --no-cache-dir --quiet
echo "✓ Uvicorn 已安装"
echo ""

# 8. 安装其他依赖
echo ">>> 7. 安装其他依赖..."
cd backend
pip install -r requirements.txt --no-cache-dir --quiet
cd ..
echo "✓ 所有依赖已安装"
echo ""

# 9. 显示新版本
echo ">>> 8. 新版本："
pip show fastapi pydantic uvicorn 2>/dev/null | grep -E "^Name|^Version"
echo ""

# 10. 测试导入
echo ">>> 9. 测试模块导入..."
cd backend
python3 << 'TEST_EOF'
import sys
try:
    import fastapi
    import pydantic
    from fastapi import Depends
    from fastapi.security import OAuth2PasswordRequestForm
    
    print(f"✓ FastAPI {fastapi.__version__} 导入成功")
    print(f"✓ Pydantic {pydantic.__version__} 导入成功")
    
    # 测试 FieldInfo 是否有 in_ 属性（Pydantic 2.x 使用 location 而不是 in_）
    from pydantic.fields import FieldInfo
    print(f"✓ FieldInfo 类可用")
    
    # 测试 Depends
    from fastapi.dependencies.utils import get_dependant
    print("✓ Depends 工具函数可用")
    
    # 测试是否可以导入应用
    print("测试导入应用模块...")
    from main import app
    print("✓ 应用模块导入成功")
    print("✓ 所有测试通过！")
    sys.exit(0)
except AttributeError as e:
    if "'FieldInfo' object has no attribute 'in_'" in str(e):
        print("✗ 仍然存在 FieldInfo.in_ 错误")
        print("这可能是 FastAPI 内部代码问题")
        print("尝试使用更旧的 Pydantic 版本...")
        sys.exit(1)
    else:
        raise
except Exception as e:
    print(f"✗ 导入失败: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
TEST_EOF

TEST_RESULT=$?

if [ $TEST_RESULT -ne 0 ]; then
    echo ""
    echo "测试失败，尝试使用 Pydantic 2.5（更稳定的版本）..."
    pip install "pydantic>=2.5.0,<2.6.0" --force-reinstall --no-cache-dir --quiet
    pip install "fastapi>=0.109.0,<0.110.0" --force-reinstall --no-cache-dir --quiet
    
    echo "重新测试..."
    python3 << 'TEST_EOF2'
    import sys
    try:
        from main import app
        print("✓ 使用 Pydantic 2.5 导入成功")
        sys.exit(0)
    except Exception as e:
        print(f"✗ 仍然失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
TEST_EOF2
    
    if [ $? -ne 0 ]; then
        echo ""
        echo "✗ 测试失败，请检查错误信息"
        deactivate
        exit 1
    fi
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
echo "✓ 升级成功！服务正常运行"
echo "=========================================="
echo ""
echo "版本信息："
pip show fastapi pydantic uvicorn 2>/dev/null | grep -E "^Name|^Version" || echo "无法获取版本信息"
echo ""

