# Local Development Startup Script
# Function: Initialize database, start backend and frontend services

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Local Development Startup Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Set project paths
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendPath = Join-Path $projectRoot "backend"
$frontendPath = Join-Path $projectRoot "frontend"
$venvPath = Join-Path $projectRoot "venv"

# Check virtual environment
Write-Host "1. Checking virtual environment..." -ForegroundColor Yellow
if (-not (Test-Path $venvPath)) {
    Write-Host "   Error: Virtual environment not found!" -ForegroundColor Red
    Write-Host "   Please create it first: python -m venv venv" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}
Write-Host "   Virtual environment found" -ForegroundColor Green
Write-Host ""

# Check backend dependencies
Write-Host "2. Checking backend dependencies..." -ForegroundColor Yellow
$venvPython = Join-Path $venvPath "Scripts\python.exe"
$venvPip = Join-Path $venvPath "Scripts\pip.exe"

if (-not (Test-Path $venvPython)) {
    Write-Host "   Error: Python executable not found at: $venvPython" -ForegroundColor Red
    exit 1
}

Write-Host "   Using Python: $venvPython" -ForegroundColor Gray

# Check requirements.txt
$requirementsPath = Join-Path $backendPath "requirements.txt"
if (Test-Path $requirementsPath) {
    Write-Host "   Checking dependencies..." -ForegroundColor Gray
    # Check if all required packages are installed
    $requiredPackages = @("fastapi", "uvicorn", "sqlalchemy", "pymysql", "python-dotenv")
    $missingPackages = @()
    
    foreach ($package in $requiredPackages) {
        $checkResult = & $venvPython -m pip show $package 2>&1 | Out-String
        # Check if package is installed (exit code 0 and no WARNING in output)
        if ($LASTEXITCODE -ne 0 -or $checkResult -match "WARNING.*not found") {
            $missingPackages += $package
        }
    }
    
    if ($missingPackages.Count -gt 0) {
        Write-Host "   Missing packages: $($missingPackages -join ', ')" -ForegroundColor Yellow
        Write-Host "   Installing dependencies (using Tsinghua mirror)..." -ForegroundColor Gray
        & $venvPython -m pip install -r $requirementsPath -i https://pypi.tuna.tsinghua.edu.cn/simple
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   Warning: Failed with mirror, trying default source..." -ForegroundColor Yellow
            & $venvPython -m pip install -r $requirementsPath
            if ($LASTEXITCODE -ne 0) {
                Write-Host "   Error: Failed to install dependencies!" -ForegroundColor Red
                Write-Host "   Please check the error message above" -ForegroundColor Yellow
                exit 1
            }
        }
        Write-Host "   Dependencies installed successfully" -ForegroundColor Green
    } else {
        Write-Host "   All dependencies ready" -ForegroundColor Green
    }
} else {
    Write-Host "   Warning: requirements.txt not found" -ForegroundColor Yellow
}
Write-Host ""

# Initialize database (only if not exists)
Write-Host "3. Checking database..." -ForegroundColor Yellow
$dbPath = Join-Path $backendPath "products.db"
if (Test-Path $dbPath) {
    Write-Host "   Existing database found, preserving data..." -ForegroundColor Green
    Write-Host "   Running init_db.py to ensure tables exist (will not overwrite existing data)..." -ForegroundColor Gray
} else {
    Write-Host "   Database not found, will initialize..." -ForegroundColor Gray
}

Push-Location $backendPath
try {
    & $venvPython init_db.py
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   Database check/initialization completed" -ForegroundColor Green
    } else {
        Write-Host "   Warning: Database initialization may have issues" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   Error: Database initialization failed: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host ""

# Check frontend dependencies
Write-Host "4. Checking frontend dependencies..." -ForegroundColor Yellow
if (-not (Test-Path (Join-Path $frontendPath "node_modules"))) {
    Write-Host "   Installing frontend dependencies (using npmmirror.com)..." -ForegroundColor Gray
    Push-Location $frontendPath
    npm install
    $npmExitCode = $LASTEXITCODE
    Pop-Location
    if ($npmExitCode -ne 0) {
        Write-Host "   Error: Failed to install frontend dependencies!" -ForegroundColor Red
        exit 1
    }
    Write-Host "   Frontend dependencies installed" -ForegroundColor Green
} else {
    Write-Host "   Frontend dependencies ready" -ForegroundColor Green
}
Write-Host ""

# Start backend service
Write-Host "5. Starting backend service..." -ForegroundColor Yellow
$backendCommand = "cd '$backendPath'; & '$venvPython' main.py"
Start-Process powershell -ArgumentList @("-NoExit", "-Command", $backendCommand)
Write-Host "   Backend service started (http://127.0.0.1:8000)" -ForegroundColor Green
Write-Host ""

# Wait for backend to start
Write-Host "   Waiting for backend to start..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# Start frontend service
Write-Host "6. Starting frontend service..." -ForegroundColor Yellow
$frontendCommand = "cd '$frontendPath'; npm run dev"
Start-Process powershell -ArgumentList @("-NoExit", "-Command", $frontendCommand)
Write-Host "   Frontend service started (http://localhost:5173)" -ForegroundColor Green
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Services started successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Backend API: http://127.0.0.1:8000" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:5173" -ForegroundColor Cyan
Write-Host "API Docs: http://127.0.0.1:8000/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "Note: Services are running in separate PowerShell windows" -ForegroundColor Yellow
Write-Host "      Close services by closing the corresponding PowerShell windows" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter to close this window (services will continue running)..."
Read-Host
