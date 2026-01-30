# Scripts 文件夹

此文件夹包含项目的辅助脚本文件。

## 脚本说明

### 开发相关

- **check-project.ps1** - 项目完整性检查脚本
  - 检查后端、前端、部署文件是否完整
  - 检查虚拟环境和依赖
  - 使用方法：`.\scripts\check-project.ps1`

- **verify-project.ps1** - 项目文件完整性验证脚本
  - 详细验证所有关键文件是否存在
  - 使用方法：`.\scripts\verify-project.ps1`

- **install-deps.ps1** - 快速安装后端依赖脚本
  - 安装 requirements.txt 中的所有依赖
  - 使用方法：`.\scripts\install-deps.ps1`

### 资源管理

- **download-icons.ps1** - 下载产品图标脚本
  - 从 Google Favicon API 下载产品图标
  - 保存到 `frontend/public/icons/`
  - 使用方法：`.\scripts\download-icons.ps1`

- **download-rag-icons.ps1** - 下载 RAG 向量数据库图标脚本
  - 从 Google Favicon API 下载 RAG 向量数据库图标
  - 保存到 `frontend/public/icons/`
  - 使用方法：`.\scripts\download-rag-icons.ps1`

### 开发工具

- **INSTALL_PLUGINS.ps1** - Vue 插件安装指南
  - 显示如何在 VS Code 中安装 Vue 相关插件
  - 使用方法：`.\scripts\INSTALL_PLUGINS.ps1`

## 注意事项

所有脚本都使用相对路径，会自动检测项目根目录。脚本可以在项目根目录或 scripts 文件夹中运行。

## 主要启动脚本

主要的启动脚本保留在项目根目录：
- `start-local.bat` - Windows 批处理启动脚本
- `start-local.ps1` - PowerShell 启动脚本

这些脚本用于启动整个开发环境（后端 + 前端）。

