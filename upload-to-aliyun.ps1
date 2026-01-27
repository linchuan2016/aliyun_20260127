# 阿里云服务器代码上传脚本
# 使用方法: .\upload-to-aliyun.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerIP,
    
    [Parameter(Mandatory=$false)]
    [string]$Username = "root"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  代码上传到阿里云服务器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ProjectPath = "D:\Aliyun\my-fullstack-app"
$RemotePath = "/var/www/my-fullstack-app"

# 检查本地项目路径
if (-not (Test-Path $ProjectPath)) {
    Write-Host "错误: 找不到项目路径 $ProjectPath" -ForegroundColor Red
    exit 1
}

Write-Host "服务器 IP: $ServerIP" -ForegroundColor Yellow
Write-Host "用户名: $Username" -ForegroundColor Yellow
Write-Host "远程路径: $RemotePath" -ForegroundColor Yellow
Write-Host ""

# 确认
$confirm = Read-Host "确认上传? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "已取消上传" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "步骤 1/4: 在服务器上创建目录..." -ForegroundColor Green
try {
    ssh "${Username}@${ServerIP}" "mkdir -p $RemotePath"
    Write-Host "✓ 目录创建成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 目录创建失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 2/4: 上传 backend 文件夹..." -ForegroundColor Green
try {
    scp -r "${ProjectPath}\backend" "${Username}@${ServerIP}:${RemotePath}/"
    Write-Host "✓ backend 上传成功" -ForegroundColor Green
} catch {
    Write-Host "✗ backend 上传失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 3/4: 上传 frontend 文件夹..." -ForegroundColor Green
try {
    scp -r "${ProjectPath}\frontend" "${Username}@${ServerIP}:${RemotePath}/"
    Write-Host "✓ frontend 上传成功" -ForegroundColor Green
} catch {
    Write-Host "✗ frontend 上传失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 4/4: 上传 deploy 文件夹..." -ForegroundColor Green
try {
    scp -r "${ProjectPath}\deploy" "${Username}@${ServerIP}:${RemotePath}/"
    Write-Host "✓ deploy 上传成功" -ForegroundColor Green
} catch {
    Write-Host "✗ deploy 上传失败: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  上传完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步操作:" -ForegroundColor Yellow
Write-Host "1. SSH 登录服务器: ssh ${Username}@${ServerIP}" -ForegroundColor White
Write-Host "2. 进入项目目录: cd $RemotePath" -ForegroundColor White
Write-Host "3. 创建虚拟环境: cd backend && python3 -m venv ../venv" -ForegroundColor White
Write-Host "4. 参考部署文档继续配置" -ForegroundColor White
Write-Host ""

