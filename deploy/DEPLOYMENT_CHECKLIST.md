# Milvus 和 Attu 部署检查清单

## 📝 部署前准备

- [ ] 确认服务器系统（推荐 CentOS 7+ 或 Ubuntu 18+）
- [ ] 确认服务器内存至少 2GB
- [ ] 确认服务器有 root 或 sudo 权限
- [ ] 确认项目代码已同步到服务器 `/var/www/my-fullstack-app`

## 🚀 部署步骤

### 步骤 1: 同步代码

```bash
cd /var/www/my-fullstack-app
git pull gitee main
```

### 步骤 2: 执行一键部署

```bash
chmod +x deploy/deploy-milvus-aliyun-complete.sh
sudo ./deploy/deploy-milvus-aliyun-complete.sh
```

### 步骤 3: 验证部署

```bash
chmod +x deploy/verify-milvus-deployment.sh
./deploy/verify-milvus-deployment.sh
```

### 步骤 4: 配置防火墙

如果验证脚本显示端口未开放：

```bash
chmod +x deploy/configure-firewall.sh
sudo ./deploy/configure-firewall.sh
```

### 步骤 5: 配置阿里云安全组

在阿里云控制台：
- [ ] 进入 ECS -> 安全组
- [ ] 添加入方向规则：
  - [ ] 端口 3000 (Attu)
  - [ ] 端口 19530 (Milvus)
  - [ ] 端口 9000 (MinIO API)
  - [ ] 端口 9001 (MinIO Console)

## ✅ 部署后验证

- [ ] Docker 已安装并运行
- [ ] Docker Compose 已安装
- [ ] 所有容器正常运行（etcd, minio, standalone, attu）
- [ ] 端口 3000 正在监听（Attu）
- [ ] 端口 19530 正在监听（Milvus）
- [ ] 可以通过浏览器访问 `http://YOUR_SERVER_IP:3000`
- [ ] 可以在 Attu 中成功连接到 Milvus

## 🔍 故障排查

如果部署失败，按以下顺序检查：

1. **检查服务状态**
   ```bash
   cd /opt/milvus
   docker-compose ps
   docker-compose logs -f
   ```

2. **检查端口监听**
   ```bash
   sudo netstat -tlnp | grep 3000
   sudo netstat -tlnp | grep 19530
   ```

3. **检查防火墙**
   ```bash
   sudo firewall-cmd --list-ports
   ```

4. **检查内存**
   ```bash
   free -h
   ```

5. **检查 Docker**
   ```bash
   docker --version
   docker-compose --version
   sudo systemctl status docker
   ```

## 📞 获取帮助

如果遇到问题：
1. 查看详细日志：`cd /opt/milvus && docker-compose logs -f`
2. 参考详细文档：`DEPLOY_MILVUS_ALIYUN.md`
3. 运行验证脚本：`./deploy/verify-milvus-deployment.sh`

