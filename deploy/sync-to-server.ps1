# Sync code to Alibaba Cloud server
# Usage: .\deploy\sync-to-server.ps1

$SERVER_IP = "47.112.29.212"
$SERVER_USER = "root"
$DEPLOY_PATH = "/var/www/my-fullstack-app"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Syncing code to Alibaba Cloud server" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Pull latest code from Gitee
Write-Host "Step 1: Pulling latest code from Gitee..." -ForegroundColor Yellow
$pullCommand = "cd $DEPLOY_PATH && git pull gitee main"
ssh "${SERVER_USER}@${SERVER_IP}" $pullCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Git pull failed" -ForegroundColor Red
    exit 1
}

Write-Host "Code pulled successfully!" -ForegroundColor Green
Write-Host ""

# Step 2: Update backend dependencies
Write-Host "Step 2: Updating backend dependencies..." -ForegroundColor Yellow
$backendCommand = "cd $DEPLOY_PATH/backend && source ../venv/bin/activate && pip install -r requirements.txt --quiet"
ssh "${SERVER_USER}@${SERVER_IP}" $backendCommand

Write-Host "Backend dependencies updated" -ForegroundColor Green
Write-Host ""

# Step 3: Initialize/Update database
Write-Host "Step 3: Initializing/Updating database..." -ForegroundColor Yellow
$dbCommand = "cd $DEPLOY_PATH/backend && source ../venv/bin/activate && python init_db.py"
ssh "${SERVER_USER}@${SERVER_IP}" $dbCommand

Write-Host "Database updated" -ForegroundColor Green
Write-Host ""

# Step 4: Build frontend
Write-Host "Step 4: Building frontend..." -ForegroundColor Yellow
$frontendCommand = "cd $DEPLOY_PATH/frontend && npm install --silent && npm run build"
ssh "${SERVER_USER}@${SERVER_IP}" $frontendCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Frontend build failed" -ForegroundColor Red
    exit 1
}

Write-Host "Frontend built successfully" -ForegroundColor Green
Write-Host ""

# Step 5: Restart services
Write-Host "Step 5: Restarting services..." -ForegroundColor Yellow
$restartCommand = "systemctl restart my-fullstack-app && systemctl restart nginx && sleep 2 && systemctl status my-fullstack-app --no-pager -l | head -10"
ssh "${SERVER_USER}@${SERVER_IP}" $restartCommand

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Sync completed!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Access URL: http://47.112.29.212" -ForegroundColor Cyan
Write-Host "HTTPS URL: https://linchuan.tech" -ForegroundColor Cyan
Write-Host ""
