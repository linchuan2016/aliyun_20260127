@echo off
echo 启动本地开发环境...
echo.
echo [1/2] 启动后端服务...
start "Backend Server" cmd /k "cd backend && ..\venv\Scripts\python.exe main.py"
timeout /t 3 /nobreak >nul
echo.
echo [2/2] 启动前端服务...
start "Frontend Server" cmd /k "cd frontend && npm run dev"
echo.
echo 开发服务器已启动！
echo 后端: http://127.0.0.1:8000
echo 前端: http://localhost:5173
echo.
echo 按任意键关闭此窗口（服务器将继续运行）...
pause >nul


