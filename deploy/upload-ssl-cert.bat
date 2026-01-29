@echo off
chcp 65001 >nul
echo ==========================================
echo SSL 证书上传工具
echo ==========================================
echo.

cd /d "D:\Aliyun\my-fullstack-app"

echo 正在创建 SSL 证书目录...
ssh root@47.112.29.212 "mkdir -p /etc/nginx/ssl/linchuan.tech"
ssh root@47.112.29.212 "chmod 700 /etc/nginx/ssl/linchuan.tech"

echo.
echo 正在上传证书文件...
scp "ssl\23255505_linchuan.tech_nginx\linchuan.tech.pem" root@47.112.29.212:/etc/nginx/ssl/linchuan.tech/fullchain.pem

if %errorlevel% neq 0 (
    echo 错误: 证书文件上传失败
    pause
    exit /b 1
)

echo.
echo 正在上传私钥文件...
scp "ssl\23255505_linchuan.tech_nginx\linchuan.tech.key" root@47.112.29.212:/etc/nginx/ssl/linchuan.tech/privkey.pem

if %errorlevel% neq 0 (
    echo 错误: 私钥文件上传失败
    pause
    exit /b 1
)

echo.
echo 正在设置文件权限...
ssh root@47.112.29.212 "chmod 600 /etc/nginx/ssl/linchuan.tech/fullchain.pem"
ssh root@47.112.29.212 "chmod 600 /etc/nginx/ssl/linchuan.tech/privkey.pem"

echo.
echo ==========================================
echo 证书上传完成！
echo ==========================================
echo.
echo 验证上传:
ssh root@47.112.29.212 "ls -la /etc/nginx/ssl/linchuan.tech/"
echo.
pause

