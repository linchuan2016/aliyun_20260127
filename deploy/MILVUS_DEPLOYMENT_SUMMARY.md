# Milvus 和 Attu 部署文件说明

## 📦 已创建的部署文件

### 🚀 一键部署脚本（推荐使用）

**`deploy-milvus-aliyun-complete.sh`**
- 完整的一键部署脚本
- 自动安装 Docker 和 Docker Compose（使用阿里云镜像源）
- 自动配置防火墙
- 自动创建目录和启动服务
- **使用方法**: `sudo ./deploy/deploy-milvus-aliyun-complete.sh`

### 🔧 辅助脚本

**`configure-firewall.sh`**
- 配置防火墙开放 Milvus 和 Attu 所需端口
- 支持 firewalld 和 iptables
- **使用方法**: `sudo ./deploy/configure-firewall.sh`

**`verify-milvus-deployment.sh`**
- 验证部署状态
- 检查 Docker、容器、端口、防火墙等
- **使用方法**: `./deploy/verify-milvus-deployment.sh`

### 📚 文档

**`QUICK_START_MILVUS.md`**
- 快速开始指南
- 包含常见问题解答
- 适合快速查阅

**`DEPLOYMENT_CHECKLIST.md`**
- 部署检查清单
- 逐步验证部署状态

**`DEPLOY_MILVUS_ALIYUN.md`**
- 详细的阿里云部署指南
- 包含故障排查

**`DEPLOY_MILVUS.md`**
- 通用部署指南
- 适用于各种 Linux 系统

## 🎯 快速开始

### 在阿里云服务器上执行：

```bash
# 1. 进入项目目录
cd /var/www/my-fullstack-app

# 2. 同步最新代码
git pull gitee main

# 3. 执行一键部署
chmod +x deploy/deploy-milvus-aliyun-complete.sh
sudo ./deploy/deploy-milvus-aliyun-complete.sh

# 4. 验证部署
chmod +x deploy/verify-milvus-deployment.sh
./deploy/verify-milvus-deployment.sh
```

### 部署完成后访问：

- **Attu 管理界面**: `http://YOUR_SERVER_IP:3000`
- **Milvus API**: `YOUR_SERVER_IP:19530`
- **MinIO 控制台**: `http://YOUR_SERVER_IP:9001`

## 📋 部署流程

```
1. 检查并安装 Docker
   ↓
2. 检查并安装 Docker Compose
   ↓
3. 配置防火墙
   ↓
4. 创建部署目录
   ↓
5. 复制配置文件
   ↓
6. 设置权限
   ↓
7. 启动服务
   ↓
8. 验证部署
```

## 🔍 服务组件

部署脚本会启动以下服务：

1. **etcd** - 元数据存储
2. **minio** - 对象存储（用于向量数据）
3. **milvus-standalone** - Milvus 向量数据库
4. **attu** - Milvus 管理界面

所有服务都通过 Docker Compose 管理，配置文件位于 `/opt/milvus/docker-compose.yml`

## 🛠️ 服务管理

```bash
cd /opt/milvus

# 查看状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 重启服务
docker-compose restart

# 停止服务
docker-compose down
```

## ⚠️ 注意事项

1. **内存要求**: Milvus 需要至少 2GB 内存
2. **端口要求**: 确保以下端口未被占用：
   - 19530 (Milvus)
   - 3000 (Attu)
   - 9000, 9001 (MinIO)
3. **防火墙**: 部署脚本会自动配置防火墙，但需要手动配置阿里云安全组
4. **数据持久化**: 数据存储在 `/opt/milvus/volumes/` 目录

## 📞 获取帮助

如果遇到问题：

1. 运行验证脚本：`./deploy/verify-milvus-deployment.sh`
2. 查看服务日志：`cd /opt/milvus && docker-compose logs -f`
3. 参考详细文档：`DEPLOY_MILVUS_ALIYUN.md`
4. 查看快速指南：`QUICK_START_MILVUS.md`

