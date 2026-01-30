# 项目完整性验证脚本
# 获取项目根目录（脚本在 scripts 文件夹中）
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Push-Location $projectRoot

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "项目文件完整性检查" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# 检查后端文件
Write-Host "[后端文件]" -ForegroundColor Yellow
$backendFiles = @(
    "backend\main.py",
    "backend\database.py", 
    "backend\models.py",
    "backend\init_db.py",
    "backend\update_icons.py",
    "backend\requirements.txt"
)
foreach ($file in $backendFiles) {
    if (Test-Path $file) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $file" -ForegroundColor Red
        $allGood = $false
    }
}

# 检查前端核心文件
Write-Host ""
Write-Host "[前端核心文件]" -ForegroundColor Yellow
$frontendCore = @(
    "frontend\package.json",
    "frontend\vite.config.js",
    "frontend\src\main.js",
    "frontend\src\App.vue",
    "frontend\src\router\index.js"
)
foreach ($file in $frontendCore) {
    if (Test-Path $file) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $file" -ForegroundColor Red
        $allGood = $false
    }
}

# 检查视图文件
Write-Host ""
Write-Host "[视图文件]" -ForegroundColor Yellow
$views = @(
    "frontend\src\views\Home.vue",
    "frontend\src\views\Tools.vue",
    "frontend\src\views\RAG.vue",
    "frontend\src\views\CalendarPage.vue",
    "frontend\src\views\NotesPage.vue"
)
foreach ($file in $views) {
    if (Test-Path $file) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $file" -ForegroundColor Red
        $allGood = $false
    }
}

# 检查组件文件
Write-Host ""
Write-Host "[组件文件]" -ForegroundColor Yellow
$components = @(
    "frontend\src\components\Navigation.vue",
    "frontend\src\components\ProductCard.vue",
    "frontend\src\components\Calendar.vue",
    "frontend\src\components\Notes.vue"
)
foreach ($file in $components) {
    if (Test-Path $file) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $file" -ForegroundColor Red
        $allGood = $false
    }
}

# 检查样式文件
Write-Host ""
Write-Host "[样式文件]" -ForegroundColor Yellow
$styles = @(
    "frontend\src\styles\App.css",
    "frontend\src\styles\Navigation.css",
    "frontend\src\styles\ProductCard.css"
)
foreach ($file in $styles) {
    if (Test-Path $file) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $file" -ForegroundColor Red
        $allGood = $false
    }
}

# 检查配置文件
Write-Host ""
Write-Host "[配置文件]" -ForegroundColor Yellow
$configs = @(
    ".gitignore",
    "README.md",
    "start-local.ps1",
    "start-local.bat",
    "scripts\install-deps.ps1"
)
foreach ($file in $configs) {
    if (Test-Path $file) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $file" -ForegroundColor Red
        $allGood = $false
    }
}

# 检查虚拟环境
Write-Host ""
Write-Host "[虚拟环境]" -ForegroundColor Yellow
if (Test-Path "venv\Scripts\python.exe") {
    Write-Host "  OK venv 存在" -ForegroundColor Green
    
    # 检查关键包
    $packages = @("fastapi", "uvicorn", "sqlalchemy", "pymysql", "python-dotenv")
    $missingPkgs = @()
    foreach ($pkg in $packages) {
        $result = & "venv\Scripts\python.exe" -m pip show $pkg 2>&1
        if ($LASTEXITCODE -eq 0 -and $result -notmatch "WARNING") {
            Write-Host "    OK $pkg" -ForegroundColor Green
        } else {
            Write-Host "    MISSING $pkg" -ForegroundColor Red
            $missingPkgs += $pkg
            $allGood = $false
        }
    }
} else {
    Write-Host "  MISSING venv" -ForegroundColor Red
    $allGood = $false
}

# 检查前端依赖
Write-Host ""
Write-Host "[前端依赖]" -ForegroundColor Yellow
if (Test-Path "frontend\node_modules\vue") {
    Write-Host "  OK node_modules 存在" -ForegroundColor Green
} else {
    Write-Host "  MISSING node_modules" -ForegroundColor Red
    $allGood = $false
}

# 检查图标文件
Write-Host ""
Write-Host "[图标文件]" -ForegroundColor Yellow
$icons = @(
    "frontend\public\icons\moltbot.png",
    "frontend\public\icons\notebooklm.png",
    "frontend\public\icons\cursor.png",
    "frontend\public\icons\milvus.png",
    "frontend\public\icons\pgvector.png",
    "frontend\public\icons\qdrant.png",
    "frontend\public\icons\myscale.png",
    "frontend\public\icons\placeholder.svg"
)
$iconCount = 0
foreach ($icon in $icons) {
    if (Test-Path $icon) {
        $iconCount++
    }
}
Write-Host "  OK 图标文件: $iconCount / $($icons.Count)" -ForegroundColor Green

# 检查部署文件
Write-Host ""
Write-Host "[部署文件]" -ForegroundColor Yellow
$deployFiles = @(
    "deploy\README.md",
    "deploy\my-fullstack-app.service",
    "deploy\nginx.conf",
    "deploy\sync-on-server.sh",
    "deploy\milvus-docker-compose.yml"
)
foreach ($file in $deployFiles) {
    if (Test-Path $file) {
        Write-Host "  OK $file" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $file" -ForegroundColor Yellow
    }
}

# 总结
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "所有关键文件完整！" -ForegroundColor Green
} else {
    Write-Host "发现缺失文件，请检查上述标记" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Pop-Location
