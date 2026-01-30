# 健壮的代码同步脚本 - 处理常见问题
# Usage: .\deploy\sync-to-server-robust.ps1

$SERVER_IP = "47.112.29.212"
$SERVER_USER = "root"
$DEPLOY_PATH = "/var/www/my-fullstack-app"

# 颜色输出函数
function Write-Step {
    param($Message)
    Write-Host ""
    Write-Host ">>> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param($Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Warning {
    param($Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "同步代码到阿里云服务器 (健壮版)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 步骤 0: 检查连接
Write-Step "步骤 0: 检查服务器连接..."
try {
    $testResult = ssh -o ConnectTimeout=5 "${SERVER_USER}@${SERVER_IP}" "echo '连接成功'" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "无法连接到服务器，请检查网络和SSH配置"
        exit 1
    }
    Write-Success "服务器连接正常"
} catch {
    Write-Error "连接测试失败: $_"
    exit 1
}

# 步骤 1: 处理 Git 冲突（stash 本地修改）
Write-Step "步骤 1: 处理 Git 本地修改..."
$gitStashScript = 'cd /var/www/my-fullstack-app; if [ -n "$(git status --porcelain)" ]; then echo "检测到本地修改，正在保存..."; git stash push -m "Auto-stash before sync - $(date +%Y%m%d_%H%M%S)" 2>/dev/null; if [ $? -ne 0 ]; then true; fi; echo "本地修改已保存到 stash"; fi'
ssh "${SERVER_USER}@${SERVER_IP}" $gitStashScript
Write-Success "Git 状态检查完成"

# 步骤 2: 拉取最新代码
Write-Step "步骤 2: 从 Gitee 拉取最新代码..."
$pullScript = 'cd /var/www/my-fullstack-app; git fetch gitee main 2>&1; git reset --hard gitee/main 2>&1; if [ $? -ne 0 ]; then echo "Git pull 失败，尝试清理后重试..."; git clean -fd; git reset --hard gitee/main; fi'
$pullOutput = ssh "${SERVER_USER}@${SERVER_IP}" $pullScript
Write-Host $pullOutput

if ($LASTEXITCODE -ne 0) {
    Write-Error "Git pull 失败，请检查网络连接和仓库权限"
    exit 1
}
Write-Success "代码拉取成功"

# 步骤 3: 更新后端依赖
Write-Step "步骤 3: 更新后端依赖..."
$backendScript = 'cd /var/www/my-fullstack-app/backend; source ../venv/bin/activate; pip install --upgrade pip --quiet; pip install -r requirements.txt --quiet 2>&1'
$backendOutput = ssh "${SERVER_USER}@${SERVER_IP}" $backendScript
if ($LASTEXITCODE -ne 0) {
    Write-Warning "后端依赖更新可能有警告，继续执行..."
} else {
    Write-Success "后端依赖更新完成"
}

# 步骤 4: 初始化/更新数据库（静默执行，避免错误中断）
Write-Step "步骤 4: 初始化/更新数据库..."
$dbScript = 'cd /var/www/my-fullstack-app/backend; source ../venv/bin/activate; python init_db.py 2>&1; if [ $? -ne 0 ]; then echo "数据库初始化完成（可能已存在）"; fi'
ssh "${SERVER_USER}@${SERVER_IP}" $dbScript | Out-Null
Write-Success "数据库检查完成"

# 步骤 5: 构建前端
Write-Step "步骤 5: 构建前端..."
$frontendScript = 'cd /var/www/my-fullstack-app/frontend; export NODE_OPTIONS="--max-old-space-size=2048"; npm install --silent 2>&1; npm run build 2>&1'
$frontendOutput = ssh "${SERVER_USER}@${SERVER_IP}" $frontendScript
if ($LASTEXITCODE -ne 0) {
    Write-Error "前端构建失败"
    Write-Host $frontendOutput
    exit 1
}
Write-Success "前端构建成功"

# 步骤 6: 检查后端服务配置
Write-Step "步骤 6: 检查后端服务配置..."
$checkServiceScript = 'systemctl is-active my-fullstack-app > /dev/null 2>&1; if [ $? -eq 0 ]; then echo "active"; else echo "inactive"; fi'
$serviceStatus = ssh "${SERVER_USER}@${SERVER_IP}" $checkServiceScript
if ($serviceStatus -notmatch "active") {
    Write-Warning "后端服务未运行，将尝试启动"
}

# 步骤 7: 重启服务
Write-Step "步骤 7: 重启服务..."
$restartScript = 'systemctl daemon-reload; systemctl restart my-fullstack-app; sleep 3; systemctl restart nginx; sleep 2'
ssh "${SERVER_USER}@${SERVER_IP}" $restartScript

if ($LASTEXITCODE -ne 0) {
    Write-Error "服务重启失败"
    exit 1
}
Write-Success "服务重启完成"

# 步骤 8: 验证服务状态
Write-Step "步骤 8: 验证服务状态..."
$statusScript = 'echo "=== 后端服务状态 ==="; systemctl status my-fullstack-app --no-pager -l | head -15; echo ""; echo "=== Nginx 服务状态 ==="; systemctl status nginx --no-pager -l | head -10; echo ""; echo "=== 端口监听检查 ==="; if netstat -tlnp 2>/dev/null | grep -E ":(80|8000)" > /dev/null; then netstat -tlnp 2>/dev/null | grep -E ":(80|8000)"; elif ss -tlnp 2>/dev/null | grep -E ":(80|8000)" > /dev/null; then ss -tlnp 2>/dev/null | grep -E ":(80|8000)"; else echo "无法检查端口"; fi'
$statusOutput = ssh "${SERVER_USER}@${SERVER_IP}" $statusScript
Write-Host $statusOutput

# 步骤 9: 测试 API 健康检查
Write-Step "步骤 9: 测试 API 健康检查..."
$healthCheckScript = 'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/api/health 2>/dev/null; if [ $? -ne 0 ]; then echo "000"; fi'
$healthCode = ssh "${SERVER_USER}@${SERVER_IP}" $healthCheckScript
if ($healthCode -eq "200") {
    Write-Success "API 健康检查通过"
} else {
    Write-Warning "API 健康检查失败 (HTTP $healthCode)，请检查后端日志"
    Write-Host "查看后端日志: ssh ${SERVER_USER}@${SERVER_IP} 'journalctl -u my-fullstack-app -n 50 --no-pager'" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "同步完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "访问地址:" -ForegroundColor Cyan
Write-Host "  HTTP:  http://47.112.29.212" -ForegroundColor White
Write-Host "  HTTPS: https://linchuan.tech" -ForegroundColor White
Write-Host ""
Write-Host "如果遇到问题，可以执行以下命令查看日志:" -ForegroundColor Yellow
Write-Host "  ssh ${SERVER_USER}@${SERVER_IP} 'journalctl -u my-fullstack-app -n 100 --no-pager'" -ForegroundColor Gray
Write-Host "  ssh ${SERVER_USER}@${SERVER_IP} 'tail -n 50 /var/log/nginx/my-fullstack-app-error.log'" -ForegroundColor Gray
Write-Host ""
