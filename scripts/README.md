# Scripts 文件夹

此文件夹包含项目的所有脚本文件，按用途分为两个子目录。

## 目录结构

```
scripts/
├── local/      # 本地开发脚本
│   └── (开发相关的 PowerShell 脚本)
└── deploy/     # 部署配置和脚本
    ├── *.service      # systemd 服务文件
    ├── nginx*.conf    # Nginx 配置文件
    ├── *.sh           # 服务器端脚本
    ├── *.ps1          # Windows 同步脚本
    └── README.md      # 部署文档
```

## 本地开发脚本 (local/)

本地开发相关的脚本（如果存在）：
- 项目检查脚本
- 依赖安装脚本
- 资源下载脚本

## 部署脚本 (deploy/)

### 主要使用的脚本

1. **代码同步**：
   - Windows: `.\scripts\deploy\sync-quick.ps1`
   - 服务器: `bash /var/www/my-fullstack-app/scripts/deploy/sync-on-server-complete.sh`

2. **服务配置**：
   - HTTP: `my-fullstack-app.service` + `nginx.conf`
   - HTTPS: `my-fullstack-app-ssl.service` + `nginx-ssl.conf`

3. **SSL 配置**：
   - `apply-ssl-complete-fixed.sh` - 应用 SSL 配置
   - `upload-ssl-cert.ps1` - 上传证书

4. **Docker 安装**：
   - `install-docker-aliyun.sh` - 标准安装
   - `install-docker-aliyun-low-memory.sh` - 低内存环境

### 详细说明

详细的部署说明请参考 `scripts/deploy/README.md` 和 `scripts/deploy/文件分类说明.md`。

## 注意事项

- 所有脚本都使用相对路径，会自动检测项目根目录
- 服务器端脚本路径已更新为 `/var/www/my-fullstack-app/scripts/deploy/`
- 本地脚本路径已更新为 `scripts/deploy/` 或 `scripts/local/`
