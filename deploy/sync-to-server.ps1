# 同步代码到阿里云服务器
# 使用方法: .\deploy\sync-to-server.ps1

$SERVER_IP = "47.112.29.212"
$SERVER_USER = "root"
$DEPLOY_PATH = "/var/www/my-fullstack-app"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "开始同步代码到阿里云服务器" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 步骤 1: 拉取最新代码
Write-Host "步骤 1: 拉取最新代码..." -ForegroundColor Yellow
$pullCommand = @"
cd $DEPLOY_PATH
if [ -n `$(git status --porcelain) ]; then
    echo '警告: 服务器上有未提交的更改，正在备份...'
    git stash
fi
echo '从 Gitee 拉取最新代码...'
git pull gitee main
if [ `$? -ne 0 ]; then
    echo '错误: Git pull 失败'
    exit 1
fi
echo '代码拉取成功！'
"@

ssh ${SERVER_USER}@${SERVER_IP} $pullCommand

if ($LASTEXITCODE -ne 0) {
    Write-Host "错误: SSH 连接或代码拉取失败" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "步骤 2: 更新后端依赖..." -ForegroundColor Yellow
$backendCommand = @"
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
pip install -r requirements.txt --quiet
echo '后端依赖更新完成'
"@

ssh ${SERVER_USER}@${SERVER_IP} $backendCommand

Write-Host ""
Write-Host "步骤 3: 初始化/更新数据库..." -ForegroundColor Yellow
$dbCommand = @"
cd $DEPLOY_PATH/backend
source ../venv/bin/activate
python init_db.py
echo '数据库更新完成'
"@

ssh ${SERVER_USER}@${SERVER_IP} $dbCommand

Write-Host ""
Write-Host "步骤 4: 构建前端..." -ForegroundColor Yellow
$frontendCommand = @"
cd $DEPLOY_PATH/frontend
npm install --silent
npm run build
echo '前端构建完成'
"@

ssh ${SERVER_USER}@${SERVER_IP} $frontendCommand

Write-Host ""
Write-Host "步骤 5: 重启服务..." -ForegroundColor Yellow
$restartCommand = @"
systemctl restart my-fullstack-app
systemctl restart nginx
echo ''
echo '服务状态:'
systemctl status my-fullstack-app --no-pager -l | head -5
systemctl status nginx --no-pager -l | head -5
"@

ssh ${SERVER_USER}@${SERVER_IP} $restartCommand

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "同步完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "访问地址: http://47.112.29.212" -ForegroundColor Cyan
Write-Host ""



