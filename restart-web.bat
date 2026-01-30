@echo off
chcp 65001 >nul
echo ==========================================
echo 重启Web服务（前端+后端）
echo ==========================================
echo.

cd /d "%~dp0"

echo 正在停止现有服务...
powershell -Command "Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }"
powershell -Command "Get-NetTCPConnection -LocalPort 5173 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }"
timeout /t 2 /nobreak >nul
echo.

echo 正在启动服务...
powershell -ExecutionPolicy Bypass -File "%~dp0start-local.ps1"

