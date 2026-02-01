# 替代启动方案：如果 Docker 无法安装，使用本地环境运行
# 这个脚本检查 Docker，如果不可用，则使用本地 Python/Node 环境

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "智能启动脚本（Docker 或本地环境）" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 检查 Docker 是否可用
$dockerAvailable = $false
try {
    $null = docker --version 2>&1
    $null = docker ps 2>&1
    $dockerAvailable = $true
} catch {
    $dockerAvailable = $false
}

if ($dockerAvailable) {
    Write-Host "✓ 检测到 Docker 环境" -ForegroundColor Green
    Write-Host "  使用 Docker 方式启动..." -ForegroundColor Yellow
    Write-Host ""
    
    # 使用 Docker 启动
    if (Test-Path "docker-start.ps1") {
        & .\docker-start.ps1
    } else {
        Write-Host "✗ docker-start.ps1 不存在" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "⚠ Docker 不可用，使用本地环境启动" -ForegroundColor Yellow
    Write-Host ""
    
    # 检查 Python 环境
    Write-Host "1. 检查 Python 环境..." -ForegroundColor Yellow
    $pythonPath = $null
    if (Test-Path "venv\Scripts\python.exe") {
        $pythonPath = "venv\Scripts\python.exe"
        Write-Host "   ✓ 找到虚拟环境: $pythonPath" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ 虚拟环境不存在，检查系统 Python..." -ForegroundColor Yellow
        try {
            $pythonVersion = python --version 2>&1
            $pythonPath = "python"
            Write-Host "   ✓ 找到系统 Python: $pythonVersion" -ForegroundColor Green
        } catch {
            Write-Host "   ✗ 未找到 Python" -ForegroundColor Red
            Write-Host "   请先安装 Python 或创建虚拟环境" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # 检查 Node.js
    Write-Host ""
    Write-Host "2. 检查 Node.js 环境..." -ForegroundColor Yellow
    try {
        $nodeVersion = node --version 2>&1
        Write-Host "   ✓ Node.js: $nodeVersion" -ForegroundColor Green
    } catch {
        Write-Host "   ✗ 未找到 Node.js" -ForegroundColor Red
        Write-Host "   请先安装 Node.js: https://nodejs.org/" -ForegroundColor Yellow
        exit 1
    }
    
    # 安装后端依赖
    Write-Host ""
    Write-Host "3. 安装后端依赖..." -ForegroundColor Yellow
    if (Test-Path "venv\Scripts\pip.exe") {
        & venv\Scripts\pip.exe install -q -r backend\requirements.txt
        Write-Host "   ✓ 后端依赖已安装" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ 跳过依赖安装（请手动安装）" -ForegroundColor Yellow
    }
    
    # 安装前端依赖
    Write-Host ""
    Write-Host "4. 安装前端依赖..." -ForegroundColor Yellow
    Push-Location frontend
    if (-not (Test-Path "node_modules")) {
        npm install --silent
        Write-Host "   ✓ 前端依赖已安装" -ForegroundColor Green
    } else {
        Write-Host "   ✓ 前端依赖已存在" -ForegroundColor Green
    }
    Pop-Location
    
    # 初始化数据库
    Write-Host ""
    Write-Host "5. 初始化数据库..." -ForegroundColor Yellow
    if (Test-Path "venv\Scripts\python.exe") {
        Push-Location backend
        & ..\venv\Scripts\python.exe init_db.py
        Pop-Location
        Write-Host "   ✓ 数据库已初始化" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ 跳过数据库初始化" -ForegroundColor Yellow
    }
    
    # 启动服务
    Write-Host ""
    Write-Host "6. 启动服务..." -ForegroundColor Yellow
    Write-Host ""
    
    # 启动后端
    Write-Host "   启动后端服务..." -ForegroundColor Gray
    $backendCommand = "cd backend; if (Test-Path '..\venv\Scripts\python.exe') { ..\venv\Scripts\python.exe main.py } else { python main.py }"
    Start-Process powershell -ArgumentList @("-NoExit", "-Command", $backendCommand)
    
    # 等待后端启动
    Start-Sleep -Seconds 3
    
    # 启动前端
    Write-Host "   启动前端服务..." -ForegroundColor Gray
    $frontendCommand = "cd frontend; npm run dev"
    Start-Process powershell -ArgumentList @("-NoExit", "-Command", $frontendCommand)
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "服务已启动（本地环境）" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "服务地址:" -ForegroundColor Cyan
    Write-Host "  后端 API: http://127.0.0.1:8000" -ForegroundColor White
    Write-Host "  前端应用: http://localhost:5173" -ForegroundColor White
    Write-Host "  API 文档: http://127.0.0.1:8000/docs" -ForegroundColor White
    Write-Host ""
    Write-Host "注意: 服务运行在独立的 PowerShell 窗口中" -ForegroundColor Yellow
    Write-Host "     关闭窗口即可停止服务" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "提示: 如果 Docker 安装成功，可以使用:" -ForegroundColor Cyan
    Write-Host "     .\docker-start.ps1" -ForegroundColor White
    Write-Host ""
    Read-Host "按 Enter 键退出"
}




