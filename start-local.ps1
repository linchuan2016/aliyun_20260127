# 启动后端
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd D:\Aliyun\my-fullstack-app\backend; ..\venv\Scripts\activate; python main.py"

# 等待2秒
Start-Sleep -Seconds 2

# 启动前端
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd D:\Aliyun\my-fullstack-app\frontend; npm run dev"

Write-Host ""
Write-Host "服务已启动！" -ForegroundColor Green
Write-Host "后端: http://127.0.0.1:8000" -ForegroundColor Cyan
Write-Host "前端: http://localhost:5173" -ForegroundColor Cyan
Write-Host ""
Write-Host "按任意键关闭此窗口（服务将继续运行）..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

