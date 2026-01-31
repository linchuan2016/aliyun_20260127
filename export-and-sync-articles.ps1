# 导出文章并同步到 Git
# 使用方法: .\export-and-sync-articles.ps1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "导出文章并同步到 Git" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 设置路径
$projectRoot = $PWD
$backendPath = Join-Path $projectRoot "backend"
$venvPython = Join-Path $projectRoot "venv\Scripts\python.exe"

# 步骤 1: 导出文章
Write-Host ">>> 步骤 1: 导出文章数据..." -ForegroundColor Yellow
Push-Location $backendPath
try {
    & $venvPython export_articles.py
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ 导出文章失败！" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ 文章导出成功" -ForegroundColor Green
} catch {
    Write-Host "✗ 导出文章失败: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
Write-Host ""

# 步骤 2: 检查 Git 状态
Write-Host ">>> 步骤 2: 检查 Git 状态..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ([string]::IsNullOrWhiteSpace($gitStatus)) {
    Write-Host "没有需要提交的更改" -ForegroundColor Gray
    Write-Host ""
    Write-Host "文章数据已是最新，无需提交" -ForegroundColor Green
    exit 0
}

Write-Host "检测到以下更改:" -ForegroundColor Gray
git status --short
Write-Host ""

# 步骤 3: 添加并提交
Write-Host ">>> 步骤 3: 提交文章数据到 Git..." -ForegroundColor Yellow
$articlesFile = Join-Path $projectRoot "data\articles.json"
if (Test-Path $articlesFile) {
    git add "data/articles.json"
    Write-Host "✓ 已添加 data/articles.json" -ForegroundColor Green
} else {
    Write-Host "✗ 找不到 data/articles.json" -ForegroundColor Red
    exit 1
}

# 检查是否有其他相关文件需要提交
$exportScript = Join-Path $backendPath "export_articles.py"
$importScript = Join-Path $backendPath "import_articles.py"
if (Test-Path $exportScript) {
    git add "backend/export_articles.py"
    Write-Host "✓ 已添加 backend/export_articles.py" -ForegroundColor Green
}
if (Test-Path $importScript) {
    git add "backend/import_articles.py"
    Write-Host "✓ 已添加 backend/import_articles.py" -ForegroundColor Green
}

# 提交
$commitMessage = "更新文章数据: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $commitMessage
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 提交失败！" -ForegroundColor Red
    exit 1
}
Write-Host "✓ 提交成功" -ForegroundColor Green
Write-Host ""

# 步骤 4: 推送到 Gitee（可选）
Write-Host ">>> 步骤 4: 是否推送到 Gitee？" -ForegroundColor Yellow
$push = Read-Host "输入 'y' 或 'yes' 推送，其他键跳过"
if ($push -eq 'y' -or $push -eq 'yes') {
    Write-Host "正在推送到 Gitee..." -ForegroundColor Gray
    git push gitee main
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ 推送成功" -ForegroundColor Green
    } else {
        Write-Host "✗ 推送失败，请手动执行: git push gitee main" -ForegroundColor Yellow
    }
} else {
    Write-Host "跳过推送，可以稍后手动执行: git push gitee main" -ForegroundColor Gray
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

