# Docker 启动脚本 (Windows PowerShell)
# 功能：检查 Docker 环境，构建并启动服务

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Docker 部署脚本" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Docker 是否安装
Write-Host "1. 检查 Docker 环境..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "   ✓ Docker 已安装: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Docker 未安装或未启动" -ForegroundColor Red
    Write-Host "   请先安装 Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# 检查 Docker 是否运行
try {
    docker ps | Out-Null
    Write-Host "   ✓ Docker 服务正在运行" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Docker 服务未运行" -ForegroundColor Red
    Write-Host "   请启动 Docker Desktop" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 检查 docker-compose
Write-Host "2. 检查 docker-compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "   ✓ docker-compose 已安装: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "   ✗ docker-compose 未安装" -ForegroundColor Red
    Write-Host "   新版本 Docker Desktop 已包含 docker-compose" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# 检查 .env 文件
Write-Host "3. 检查环境变量配置..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "   ✓ .env 文件存在" -ForegroundColor Green
} else {
    Write-Host "   ⚠ .env 文件不存在，从 env.example 创建..." -ForegroundColor Yellow
    if (Test-Path "env.example") {
        Copy-Item "env.example" ".env"
        Write-Host "   ✓ 已创建 .env 文件，请根据需要修改配置" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ env.example 文件不存在，将使用默认配置" -ForegroundColor Yellow
    }
}

Write-Host ""

# 确保数据目录存在
Write-Host "4. 检查数据目录..." -ForegroundColor Yellow
$dataDir = "data"
if (-not (Test-Path $dataDir)) {
    New-Item -ItemType Directory -Path $dataDir | Out-Null
    New-Item -ItemType Directory -Path "$dataDir/article-covers" | Out-Null
    New-Item -ItemType Directory -Path "$dataDir/book-covers" | Out-Null
    Write-Host "   ✓ 已创建数据目录" -ForegroundColor Green
} else {
    Write-Host "   ✓ 数据目录存在" -ForegroundColor Green
}

Write-Host ""

# 构建并启动服务
Write-Host "5. 构建 Docker 镜像..." -ForegroundColor Yellow
docker-compose build
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ✗ 构建失败" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ 构建成功" -ForegroundColor Green
Write-Host ""

Write-Host "6. 启动服务..." -ForegroundColor Yellow
docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ✗ 启动失败" -ForegroundColor Red
    exit 1
}
Write-Host "   ✓ 服务已启动" -ForegroundColor Green
Write-Host ""

# 等待服务就绪
Write-Host "7. 等待服务就绪..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# 检查服务状态
Write-Host ""
Write-Host "8. 检查服务状态..." -ForegroundColor Yellow
docker-compose ps
Write-Host ""

# 测试后端健康检查
Write-Host "9. 测试后端服务..." -ForegroundColor Yellow
Start-Sleep -Seconds 3
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8000/api/health" -TimeoutSec 5 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✓ 后端服务正常 (HTTP $($response.StatusCode))" -ForegroundColor Green
        Write-Host "   响应: $($response.Content)" -ForegroundColor Gray
    }
} catch {
    Write-Host "   ⚠ 后端服务可能尚未完全启动，请稍后重试" -ForegroundColor Yellow
    Write-Host "   错误: $_" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "部署完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "服务地址:" -ForegroundColor Cyan
Write-Host "  后端 API: http://localhost:8000" -ForegroundColor White
Write-Host "  前端应用: http://localhost:5173" -ForegroundColor White
Write-Host "  API 文档: http://localhost:8000/docs" -ForegroundColor White
Write-Host ""
Write-Host "常用命令:" -ForegroundColor Cyan
Write-Host "  查看日志: docker-compose logs -f" -ForegroundColor White
Write-Host "  停止服务: docker-compose down" -ForegroundColor White
Write-Host "  重启服务: docker-compose restart" -ForegroundColor White
Write-Host "  查看状态: docker-compose ps" -ForegroundColor White
Write-Host ""
Read-Host "按 Enter 键退出"

