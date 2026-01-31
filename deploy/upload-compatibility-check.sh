#!/bin/bash
# 上传兼容性检查脚本到服务器（在本地执行）
# 使用方法: bash deploy/upload-compatibility-check.sh

SERVER_IP="47.112.29.212"  # 请根据实际情况修改
SERVER_USER="root"          # 请根据实际情况修改

echo "正在上传 检查Python兼容性.py 到服务器..."

scp deploy/检查Python兼容性.py "${SERVER_USER}@${SERVER_IP}:/var/www/my-fullstack-app/deploy/"

echo "上传完成！"
echo ""
echo "在服务器上执行检查："
echo "  cd /var/www/my-fullstack-app"
echo "  python3 deploy/检查Python兼容性.py"

