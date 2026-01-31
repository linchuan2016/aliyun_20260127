# Quick sync script - single SSH connection
# Usage: .\scripts\deploy\sync-quick.ps1

$SERVER_IP = "47.112.29.212"
$SERVER_USER = "root"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Syncing code to Aliyun server" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Execute all commands in one SSH connection (bash commands)
$allCommands = 'cd /var/www/my-fullstack-app && git stash push -m backup-$(date +%Y%m%d_%H%M%S) 2>/dev/null || true && git fetch gitee main && git reset --hard gitee/main && cd backend && source ../venv/bin/activate && pip install --upgrade pip --quiet && pip install -r requirements.txt --quiet && python init_db.py 2>&1 || echo "DB init done" && (if [ -f ../data/articles.json ]; then python import_articles.py 2>&1 || echo "Articles imported"; else echo "No articles.json"; fi) && cd ../frontend && export NODE_OPTIONS="--max-old-space-size=2048" && npm install --silent && npm run build && systemctl daemon-reload && systemctl restart my-fullstack-app && sleep 5 && systemctl restart nginx && sleep 2 && echo "=== Service Status ===" && systemctl status my-fullstack-app --no-pager -l | head -15 && echo "" && echo "=== API Health Check ===" && curl -s http://127.0.0.1:8000/api/health && echo "" && echo "Sync completed!"'

Write-Host "Executing sync (single SSH connection)..." -ForegroundColor Yellow
Write-Host ""

ssh "${SERVER_USER}@${SERVER_IP}" $allCommands

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "Sync completed successfully!" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access URLs:" -ForegroundColor Cyan
    Write-Host "  HTTP:  http://47.112.29.212" -ForegroundColor White
    Write-Host "  HTTPS: https://linchuan.tech" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Sync failed. Please check the output above." -ForegroundColor Red
    Write-Host ""
}
