#!/bin/bash

# 修复阿里云服务器缺少编译工具的问题
# 使用方法: ./fix-compiler.sh

echo "=========================================="
echo "安装编译工具和依赖"
echo "=========================================="
echo ""

# 检测系统类型并安装相应的编译工具
if [ -f /etc/redhat-release ]; then
    # CentOS/RHEL/Alibaba Cloud Linux
    echo "检测到 CentOS/RHEL/Alibaba Cloud Linux 系统"
    echo "正在安装 gcc-c++ 和 python3-devel..."
    yum install -y gcc gcc-c++ python3-devel
elif [ -f /etc/debian_version ]; then
    # Debian/Ubuntu
    echo "检测到 Debian/Ubuntu 系统"
    echo "正在安装 build-essential 和 python3-dev..."
    apt-get update
    apt-get install -y build-essential python3-dev
else
    echo "未知系统类型，尝试通用安装..."
    yum install -y gcc gcc-c++ python3-devel 2>/dev/null || \
    apt-get update && apt-get install -y build-essential python3-dev
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "编译工具安装成功！"
    echo ""
    echo "接下来请执行："
    echo "1. 升级 pip: pip install --upgrade pip"
    echo "2. 重新安装依赖: pip install -r requirements.txt"
    echo "3. 初始化数据库: python init_db.py"
else
    echo ""
    echo "错误: 编译工具安装失败"
    exit 1
fi



