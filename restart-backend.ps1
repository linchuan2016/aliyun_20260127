# 重启后端服务脚本
Write-Host "正在重启后端服务..." -ForegroundColor Yellow

# 查找并停止现有的Python/uvicorn进程
$processes = Get-Process | Where-Object {
    ($_.ProcessName -like "*python*" -or $_.ProcessName -like "*uvicorn*") -and
    $_.CommandLine -like "*main:app*"
}

if ($processes) {
    Write-Host "找到运行中的后端服务，正在停止..." -ForegroundColor Yellow
    $processes | Stop-Process -Force
    Start-Sleep -Seconds 2
}

# 启动后端服务
$backendPath = Join-Path $PSScriptRoot "backend"
$venvPython = Join-Path $PSScriptRoot "venv\Scripts\python.exe"

if (-not (Test-Path $venvPython)) {
    Write-Host "错误: 找不到Python虚拟环境!" -ForegroundColor Red
    exit 1
}

Write-Host "启动后端服务..." -ForegroundColor Green
Push-Location $backendPath
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "& '$venvPython' -m uvicorn main:app --reload --host 127.0.0.1 --port 8000"
)
Pop-Location

Write-Host "后端服务已启动 (http://127.0.0.1:8000)" -ForegroundColor Green
Write-Host "等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# 测试API
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/health" -UseBasicParsing -TimeoutSec 5
    Write-Host "后端服务运行正常!" -ForegroundColor Green
} catch {
    Write-Host "警告: 无法连接到后端服务，请检查服务是否正常启动" -ForegroundColor Yellow
}

