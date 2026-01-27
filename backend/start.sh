#!/bin/bash
# 生产环境启动脚本

# 激活虚拟环境（如果使用虚拟环境）
# source /path/to/venv/bin/activate

# 设置环境变量
export HOST=0.0.0.0
export PORT=8000
export ALLOWED_ORIGINS="http://your-domain.com,https://your-domain.com"

# 使用 uvicorn 启动应用
uvicorn main:app --host $HOST --port $PORT --workers 4

