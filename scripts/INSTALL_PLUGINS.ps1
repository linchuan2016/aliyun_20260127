# Vue Syntax Highlighting Plugin Installer
# Run this script to get instructions for installing Vue plugins

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Vue Plugin Installation Guide" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Open Extensions Panel" -ForegroundColor Yellow
Write-Host "   Press: Ctrl+Shift+X" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Install Required Plugins" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Plugin 1: Volar (Vue Language Features)" -ForegroundColor White
Write-Host "   - Search for: Volar" -ForegroundColor Gray
Write-Host "   - Author: Vue" -ForegroundColor Gray
Write-Host "   - Plugin ID: Vue.volar" -ForegroundColor Gray
Write-Host ""
Write-Host "   Plugin 2: TypeScript Vue Plugin (Volar)" -ForegroundColor White
Write-Host "   - Search for: TypeScript Vue Plugin" -ForegroundColor Gray
Write-Host "   - Author: Vue" -ForegroundColor Gray
Write-Host "   - Plugin ID: Vue.vscode-typescript-vue-plugin" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 3: Recommended Plugin" -ForegroundColor Yellow
Write-Host "   - Prettier - Code formatter" -ForegroundColor White
Write-Host "   - Plugin ID: esbenp.prettier-vscode" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 4: Reload Window" -ForegroundColor Yellow
Write-Host "   Press: Ctrl+Shift+P" -ForegroundColor Green
Write-Host "   Type: Reload Window" -ForegroundColor Green
Write-Host "   Press: Enter" -ForegroundColor Green
Write-Host ""

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "For detailed guide, see: .vscode/INSTALL_VUE_PLUGINS.md" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Try to open extensions panel
$codePaths = @(
    "$env:LOCALAPPDATA\Programs\Cursor\Cursor.exe",
    "$env:PROGRAMFILES\Cursor\Cursor.exe",
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:PROGRAMFILES\Microsoft VS Code\Code.exe"
)

foreach ($path in $codePaths) {
    if (Test-Path $path) {
        Write-Host "Opening extensions panel..." -ForegroundColor Green
        Start-Process $path -ArgumentList "--command", "workbench.view.extensions"
        break
    }
}

Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Gray
Read-Host
