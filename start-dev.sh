#!/bin/bash
# 本地开发启动脚本（Linux/Mac）

echo "启动本地开发环境..."
echo ""

# 检查后端依赖
if [ ! -d "../venv" ]; then
    echo "创建 Python 虚拟环境..."
    python3 -m venv ../venv
fi

# 启动后端
echo "[1/2] 启动后端服务..."
cd backend
source ../venv/bin/activate
pip install -q -r requirements.txt
python main.py &
BACKEND_PID=$!
cd ..

# 等待后端启动
sleep 3

# 启动前端
echo "[2/2] 启动前端服务..."
cd frontend
if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    npm install
fi
npm run dev &
FRONTEND_PID=$!
cd ..

echo ""
echo "开发服务器已启动！"
echo "后端: http://127.0.0.1:8000"
echo "前端: http://localhost:5173"
echo ""
echo "按 Ctrl+C 停止所有服务"

# 等待用户中断
trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT
wait


