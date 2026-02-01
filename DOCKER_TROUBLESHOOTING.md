# Docker 安装问题排查指南

## 🔍 问题：Docker Desktop 安装卡住

### 常见原因和解决方案

#### 1. WSL2 未安装或配置问题（Windows）

**检查 WSL2：**
```powershell
# 检查 WSL 版本
wsl --list --verbose

# 如果显示版本 1，需要升级到 WSL2
wsl --set-default-version 2
```

**手动安装 WSL2：**
```powershell
# 以管理员身份运行 PowerShell
wsl --install

# 或手动安装
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

# 重启后，设置默认版本
wsl --set-default-version 2
```

#### 2. 虚拟化未启用

**检查虚拟化：**
- 打开任务管理器 → 性能 → CPU
- 查看"虚拟化"是否已启用

**启用虚拟化：**
1. 重启电脑进入 BIOS/UEFI
2. 找到 "Virtualization Technology" 或 "Intel VT-x" / "AMD-V"
3. 启用并保存

#### 3. Hyper-V 冲突

**禁用 Hyper-V（如果不需要）：**
```powershell
# 以管理员身份运行
dism.exe /Online /Disable-Feature:Microsoft-Hyper-V
```

#### 4. 防火墙/杀毒软件阻止

- 临时关闭防火墙和杀毒软件
- 将 Docker 添加到白名单

#### 5. 网络问题（下载慢）

**使用国内镜像源：**
- 阿里云镜像加速器
- 腾讯云镜像加速器

---

## 🚀 替代方案

### 方案 1: 使用 WSL2 + Docker Engine（推荐）

不安装 Docker Desktop，直接在 WSL2 中安装 Docker Engine：

```bash
# 在 WSL2 中执行
# 1. 更新系统
sudo apt update && sudo apt upgrade -y

# 2. 安装 Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 3. 启动 Docker
sudo service docker start

# 4. 将用户添加到 docker 组（避免每次 sudo）
sudo usermod -aG docker $USER

# 5. 安装 docker-compose
sudo apt install docker-compose -y
```

### 方案 2: 使用 Podman（Docker 替代品）

Podman 不需要守护进程，更轻量：

```powershell
# Windows 安装 Podman
winget install RedHat.Podman

# 或使用 Chocolatey
choco install podman
```

**使用 Podman：**
```bash
# Podman 命令与 Docker 兼容
podman-compose up -d  # 替代 docker-compose
```

### 方案 3: 使用虚拟机（VirtualBox/VMware）

在虚拟机中安装 Linux，然后在 Linux 中安装 Docker。

### 方案 4: 直接在本地运行（无需 Docker）

如果 Docker 安装困难，可以暂时跳过 Docker，直接使用现有方式运行：

```powershell
# 使用现有的启动脚本
.\start-local.ps1
```

---

## 🔧 快速修复步骤

### Windows 10/11 完整修复流程

1. **检查系统要求**
   ```powershell
   # 检查 Windows 版本（需要 10/11 64位）
   winver
   ```

2. **安装/更新 WSL2**
   ```powershell
   # 以管理员身份运行
   wsl --install -d Ubuntu
   wsl --set-default-version 2
   ```

3. **重启电脑**

4. **重新安装 Docker Desktop**
   - 下载最新版本
   - 以管理员身份安装
   - 安装时选择 "Use WSL 2 instead of Hyper-V"

5. **配置 Docker Desktop**
   - Settings → General → 启用 "Use the WSL 2 based engine"
   - Settings → Resources → 分配足够内存（至少 2GB）

---

## 📋 检查清单

在安装 Docker 前，确认：

- [ ] Windows 10/11 64位系统
- [ ] 已启用虚拟化（BIOS/UEFI）
- [ ] 已安装 WSL2
- [ ] 有足够内存（至少 4GB 可用）
- [ ] 防火墙/杀毒软件已配置
- [ ] 以管理员身份运行安装程序

---

## 🆘 如果仍然无法安装

### 选项 1: 使用云服务器测试

在阿里云服务器上直接安装 Docker（Linux 环境更简单）：

```bash
# 在阿里云服务器上
curl -fsSL https://get.docker.com | bash
sudo systemctl start docker
sudo systemctl enable docker
```

### 选项 2: 使用 GitHub Codespaces / GitPod

在线开发环境，已预装 Docker。

### 选项 3: 暂时跳过 Docker

使用现有的本地开发方式，Docker 配置已准备好，等环境就绪后再使用。

---

## 💡 建议

如果 Docker Desktop 安装困难，建议：

1. **短期**：使用 `start-local.ps1` 在本地直接运行
2. **中期**：在阿里云服务器上测试 Docker 部署
3. **长期**：解决本地 Docker 环境后，再使用 Docker 开发

所有 Docker 配置文件已准备好，随时可以使用！




