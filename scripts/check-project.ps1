# 项目完整性检查脚本
$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "项目完整性检查" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$errors = @()
$warnings = @()

# 获取项目根目录（脚本在 scripts 文件夹中）
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Push-Location $projectRoot

# 检查后端文件
Write-Host "检查后端文件..." -ForegroundColor Yellow
$backendFiles = @(
    "backend\main.py",
    "backend\database.py",
    "backend\models.py",
    "backend\init_db.py",
    "backend\update_icons.py",
    "backend\requirements.txt"
)

foreach ($file in $backendFiles) {
    $filePath = Join-Path $projectRoot $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (缺失)" -ForegroundColor Red
        $errors += $file
    }
}

# 检查前端文件
Write-Host ""
Write-Host "检查前端文件..." -ForegroundColor Yellow
$frontendFiles = @(
    "frontend\package.json",
    "frontend\vite.config.js",
    "frontend\src\App.vue",
    "frontend\src\main.js",
    "frontend\src\router\index.js",
    "frontend\src\views\Home.vue",
    "frontend\src\views\Tools.vue",
    "frontend\src\views\RAG.vue",
    "frontend\src\views\CalendarPage.vue",
    "frontend\views\NotesPage.vue",
    "frontend\src\components\Navigation.vue",
    "frontend\src\components\ProductCard.vue"
)

foreach ($file in $frontendFiles) {
    $filePath = Join-Path $projectRoot $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (缺失)" -ForegroundColor Red
        $errors += $file
    }
}

# 检查部署文件
Write-Host ""
Write-Host "检查部署文件..." -ForegroundColor Yellow
$deployFiles = @(
    "deploy\README.md",
    "deploy\my-fullstack-app.service",
    "deploy\nginx.conf",
    "deploy\sync-on-server.sh",
    "deploy\milvus-docker-compose.yml",
    "deploy\deploy-milvus.sh"
)

foreach ($file in $deployFiles) {
    $filePath = Join-Path $projectRoot $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ $file (缺失)" -ForegroundColor Yellow
        $warnings += $file
    }
}

# 检查虚拟环境
Write-Host ""
Write-Host "检查虚拟环境..." -ForegroundColor Yellow
$venvPython = Join-Path $projectRoot "venv\Scripts\python.exe"
if (Test-Path $venvPython) {
    Write-Host "  ✓ venv 目录存在" -ForegroundColor Green
    
    # 检查关键包
    $requiredPackages = @("fastapi", "uvicorn", "sqlalchemy", "pymysql", "python-dotenv")
    $missingPackages = @()
    
    foreach ($package in $requiredPackages) {
        $result = & $venvPython -m pip show $package 2>&1
        if ($LASTEXITCODE -eq 0 -and $result -notmatch "WARNING.*not found") {
            Write-Host "    ✓ $package" -ForegroundColor Green
        } else {
            Write-Host "    ✗ $package (缺失)" -ForegroundColor Red
            $missingPackages += $package
        }
    }
    
    if ($missingPackages.Count -gt 0) {
        $warnings += "venv 缺少包: $($missingPackages -join ', ')"
    }
} else {
    Write-Host "  ✗ venv 目录不存在" -ForegroundColor Red
    $errors += "venv"
}

# 检查前端依赖
Write-Host ""
Write-Host "检查前端依赖..." -ForegroundColor Yellow
$nodeModules = Join-Path $projectRoot "frontend\node_modules"
if (Test-Path $nodeModules) {
    $vuePath = Join-Path $nodeModules "vue"
    if (Test-Path $vuePath) {
        Write-Host "  ✓ node_modules 存在" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ node_modules 存在但可能不完整" -ForegroundColor Yellow
        $warnings += "前端依赖可能不完整"
    }
} else {
    Write-Host "  ⚠ node_modules 不存在" -ForegroundColor Yellow
    $warnings += "前端依赖未安装"
}

# 检查配置文件
Write-Host ""
Write-Host "检查配置文件..." -ForegroundColor Yellow
$configFiles = @(
    ".gitignore",
    "README.md",
    "start-local.ps1",
    "start-local.bat"
)

foreach ($file in $configFiles) {
    $filePath = Join-Path $projectRoot $file
    if (Test-Path $filePath) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ $file (缺失)" -ForegroundColor Yellow
        $warnings += $file
    }
}

# 总结
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($errors.Count -eq 0 -and $warnings.Count -eq 0) {
    Write-Host "✓ 项目完整性检查通过！" -ForegroundColor Green
} else {
    if ($errors.Count -gt 0) {
        Write-Host "✗ 发现 $($errors.Count) 个错误" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    if ($warnings.Count -gt 0) {
        Write-Host "⚠ 发现 $($warnings.Count) 个警告" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "  - $warning" -ForegroundColor Yellow
        }
    }
}
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""


