# 简化的同步脚本
$SERVER_IP = "47.112.29.212"
$SERVER_USER = "root"

Write-Host "开始同步代码到阿里云服务器..." -ForegroundColor Cyan
Write-Host ""

# 步骤 1: 同步代码
Write-Host "步骤 1: 同步代码..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "cd /var/www/my-fullstack-app; git stash push -m backup 2>/dev/null; git fetch gitee main; git reset --hard gitee/main"
if ($LASTEXITCODE -ne 0) {
    Write-Host "代码同步失败" -ForegroundColor Red
    exit 1
}
Write-Host "代码同步成功" -ForegroundColor Green
Write-Host ""

# 步骤 2: 更新后端依赖
Write-Host "步骤 2: 更新后端依赖..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "cd /var/www/my-fullstack-app/backend; source ../venv/bin/activate; pip install --upgrade pip --quiet; pip install -r requirements.txt --quiet"
Write-Host "后端依赖更新完成" -ForegroundColor Green
Write-Host ""

# 步骤 3: 初始化数据库
Write-Host "步骤 3: 初始化数据库..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "cd /var/www/my-fullstack-app/backend; source ../venv/bin/activate; python init_db.py"
Write-Host "数据库初始化完成" -ForegroundColor Green
Write-Host ""

# 步骤 4: 构建前端
Write-Host "步骤 4: 构建前端..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "cd /var/www/my-fullstack-app/frontend; export NODE_OPTIONS='--max-old-space-size=2048'; npm install --silent; npm run build"
if ($LASTEXITCODE -ne 0) {
    Write-Host "前端构建失败" -ForegroundColor Red
    exit 1
}
Write-Host "前端构建成功" -ForegroundColor Green
Write-Host ""

# 步骤 5: 重启服务
Write-Host "步骤 5: 重启服务..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "systemctl daemon-reload; systemctl restart my-fullstack-app; sleep 3; systemctl restart nginx; sleep 2"
if ($LASTEXITCODE -ne 0) {
    Write-Host "服务重启失败" -ForegroundColor Red
    exit 1
}
Write-Host "服务重启完成" -ForegroundColor Green
Write-Host ""

# 步骤 6: 检查服务状态
Write-Host "步骤 6: 检查服务状态..." -ForegroundColor Yellow
ssh "${SERVER_USER}@${SERVER_IP}" "systemctl status my-fullstack-app --no-pager -l | head -15"
Write-Host ""

Write-Host "==========================================" -ForegroundColor Green
Write-Host "同步完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "访问地址:" -ForegroundColor Cyan
Write-Host "  HTTP:  http://47.112.29.212" -ForegroundColor White
Write-Host "  HTTPS: https://linchuan.tech" -ForegroundColor White
Write-Host ""

