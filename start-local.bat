@echo off
chcp 65001 >nul
echo ==========================================
echo 本地开发环境启动脚本
echo ==========================================
echo.

cd /d "%~dp0"

powershell -ExecutionPolicy Bypass -File "%~dp0start-local.ps1"

pause

