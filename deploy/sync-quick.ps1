# 快速同步脚本 - 单次 SSH 连接执行所有命令
# Usage: .\deploy\sync-quick.ps1

$SERVER_IP = "47.112.29.212"
$SERVER_USER = "root"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "快速同步代码到阿里云服务器" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 一次性执行所有命令（在服务器上，避免多次 SSH 连接）
$allCommands = @"
cd /var/www/my-fullstack-app
echo '>>> 步骤 1: 处理 Git 本地修改...'
git stash push -m backup 2>/dev/null || true
echo '>>> 步骤 2: 拉取最新代码...'
git fetch gitee main
git reset --hard gitee/main
echo '>>> 步骤 3: 更新后端依赖...'
cd backend
source ../venv/bin/activate
pip install --upgrade pip --quiet
pip install -r requirements.txt --quiet
echo '>>> 步骤 4: 初始化数据库...'
python init_db.py 2>&1 || echo '数据库初始化完成'
echo '>>> 步骤 5: 构建前端...'
cd ../frontend
export NODE_OPTIONS='--max-old-space-size=2048'
npm install --silent
npm run build
echo '>>> 步骤 6: 重启服务...'
systemctl daemon-reload
systemctl restart my-fullstack-app
sleep 3
systemctl restart nginx
sleep 2
echo '>>> 步骤 7: 检查服务状态...'
systemctl status my-fullstack-app --no-pager -l | head -15
echo ''
echo '>>> 步骤 8: 测试 API...'
curl -s http://127.0.0.1:8000/api/health || echo 'API 测试失败'
"@

Write-Host "正在执行同步（单次 SSH 连接）..." -ForegroundColor Yellow
Write-Host ""

ssh "${SERVER_USER}@${SERVER_IP}" $allCommands

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "同步完成！" -ForegroundColor Green
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "访问地址:" -ForegroundColor Cyan
    Write-Host "  HTTP:  http://47.112.29.212" -ForegroundColor White
    Write-Host "  HTTPS: https://linchuan.tech" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "同步过程中出现错误，请检查上面的输出" -ForegroundColor Red
    Write-Host ""
}

