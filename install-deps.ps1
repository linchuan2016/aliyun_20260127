# Quick dependency installation script
# Use this if dependencies are missing

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "Installing backend dependencies..." -ForegroundColor Cyan
Write-Host ""

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendPath = Join-Path $projectRoot "backend"
$venvPath = Join-Path $projectRoot "venv"
$venvPython = Join-Path $venvPath "Scripts\python.exe"
$requirementsPath = Join-Path $backendPath "requirements.txt"

if (-not (Test-Path $venvPython)) {
    Write-Host "Error: Virtual environment not found!" -ForegroundColor Red
    Write-Host "Please create it first: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $requirementsPath)) {
    Write-Host "Error: requirements.txt not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Installing packages from requirements.txt..." -ForegroundColor Yellow
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r $requirementsPath

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Error: Failed to install dependencies!" -ForegroundColor Red
    exit 1
}

