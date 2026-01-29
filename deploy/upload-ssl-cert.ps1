# PowerShell 脚本：上传 SSL 证书到阿里云服务器
# 使用方法: .\deploy\upload-ssl-cert.ps1

param(
    [string]$CertPath = "",
    [string]$KeyPath = "",
    [string]$ServerIP = "47.112.29.212",
    [string]$ServerUser = "root"
)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SSL 证书上传工具" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查参数
if ([string]::IsNullOrEmpty($CertPath)) {
    Write-Host "请输入证书文件路径（.pem 或 .crt）:" -ForegroundColor Yellow
    $CertPath = Read-Host
}

if ([string]::IsNullOrEmpty($KeyPath)) {
    Write-Host "请输入私钥文件路径（.key）:" -ForegroundColor Yellow
    $KeyPath = Read-Host
}

# 检查文件是否存在
if (-not (Test-Path $CertPath)) {
    Write-Host "错误: 证书文件不存在: $CertPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $KeyPath)) {
    Write-Host "错误: 私钥文件不存在: $KeyPath" -ForegroundColor Red
    exit 1
}

Write-Host "服务器: $ServerUser@$ServerIP" -ForegroundColor Green
Write-Host "证书文件: $CertPath" -ForegroundColor Green
Write-Host "私钥文件: $KeyPath" -ForegroundColor Green
Write-Host ""

# 创建 SSL 证书目录
Write-Host "正在创建 SSL 证书目录..." -ForegroundColor Yellow
ssh "${ServerUser}@${ServerIP}" "mkdir -p /etc/nginx/ssl/linchuan.tech && chmod 700 /etc/nginx/ssl/linchuan.tech"

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 无法创建目录" -ForegroundColor Red
    exit 1
}

# 上传证书文件
Write-Host "正在上传证书文件..." -ForegroundColor Yellow
scp $CertPath "${ServerUser}@${ServerIP}:/etc/nginx/ssl/linchuan.tech/fullchain.pem"

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 证书文件上传失败" -ForegroundColor Red
    exit 1
}

# 上传私钥文件
Write-Host "正在上传私钥文件..." -ForegroundColor Yellow
scp $KeyPath "${ServerUser}@${ServerIP}:/etc/nginx/ssl/linchuan.tech/privkey.pem"

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: 私钥文件上传失败" -ForegroundColor Red
    exit 1
}

# 设置文件权限
Write-Host "正在设置文件权限..." -ForegroundColor Yellow
ssh "${ServerUser}@${ServerIP}" "chmod 600 /etc/nginx/ssl/linchuan.tech/fullchain.pem && chmod 600 /etc/nginx/ssl/linchuan.tech/privkey.pem"

if ($LASTEXITCODE -ne 0) {
    Write-Host "警告: 设置文件权限失败" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "证书上传完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "下一步操作:" -ForegroundColor Cyan
Write-Host "1. 上传 Nginx 配置: scp deploy/nginx-ssl.conf root@${ServerIP}:/etc/nginx/sites-available/my-fullstack-app" -ForegroundColor White
Write-Host "2. 测试配置: ssh root@${ServerIP} 'nginx -t'" -ForegroundColor White
Write-Host "3. 重载 Nginx: ssh root@${ServerIP} 'systemctl reload nginx'" -ForegroundColor White
Write-Host ""
Write-Host "详细说明请查看: deploy/DEPLOY_SSL.md" -ForegroundColor Yellow
Write-Host ""

