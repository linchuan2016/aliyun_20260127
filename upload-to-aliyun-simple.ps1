# 简化版上传脚本 - 直接执行
# 修改下面的 SERVER_IP 为你的服务器 IP

$SERVER_IP = "你的服务器IP"  # 修改这里！
$USERNAME = "root"
$PROJECT_PATH = "D:\Aliyun\my-fullstack-app"
$REMOTE_PATH = "/var/www/my-fullstack-app"

Write-Host "开始上传代码到阿里云服务器..." -ForegroundColor Cyan
Write-Host "服务器: ${USERNAME}@${SERVER_IP}" -ForegroundColor Yellow
Write-Host ""

# 创建目录
Write-Host "[1/4] 创建服务器目录..." -ForegroundColor Green
ssh "${USERNAME}@${SERVER_IP}" "mkdir -p $REMOTE_PATH"

# 上传 backend
Write-Host "[2/4] 上传 backend..." -ForegroundColor Green
scp -r "${PROJECT_PATH}\backend" "${USERNAME}@${SERVER_IP}:${REMOTE_PATH}/"

# 上传 frontend
Write-Host "[3/4] 上传 frontend..." -ForegroundColor Green
scp -r "${PROJECT_PATH}\frontend" "${USERNAME}@${SERVER_IP}:${REMOTE_PATH}/"

# 上传 deploy
Write-Host "[4/4] 上传 deploy..." -ForegroundColor Green
scp -r "${PROJECT_PATH}\deploy" "${USERNAME}@${SERVER_IP}:${REMOTE_PATH}/"

Write-Host ""
Write-Host "✓ 上传完成！" -ForegroundColor Green
Write-Host ""
Write-Host "现在可以 SSH 登录服务器继续部署：" -ForegroundColor Yellow
Write-Host "ssh ${USERNAME}@${SERVER_IP}" -ForegroundColor White

