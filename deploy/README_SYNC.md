# 脚本同步指南

## 问题
新创建的脚本在本地，但服务器上还没有，需要先同步。

## 解决方案

### 方案 1：通过 Git 同步（推荐，适合长期维护）

#### 步骤 1：在本地提交并推送

```bash
# 1. 添加所有新脚本
git add deploy/*.sh deploy/*.py

# 2. 提交
git commit -m "添加部署脚本：修复 FastAPI 版本兼容性问题"

# 3. 推送到 Gitee
git push gitee main
# 或者
git push gitee master
```

#### 步骤 2：在服务器上拉取

```bash
cd /var/www/my-fullstack-app
git pull gitee main
# 或者
git pull gitee master
```

#### 步骤 3：执行脚本

```bash
cd /var/www/my-fullstack-app
bash deploy/force-install-correct-versions.sh
```

---

### 方案 2：直接在服务器上创建脚本（最快，适合临时使用）

在服务器上执行：

```bash
cd /var/www/my-fullstack-app
bash deploy/create-scripts-on-server.sh
```

或者手动创建：

```bash
cd /var/www/my-fullstack-app/deploy

# 创建脚本
cat > force-install-correct-versions.sh << 'EOF'
#!/bin/bash
# ... (脚本内容)
EOF

chmod +x force-install-correct-versions.sh
```

---

### 方案 3：使用 scp 直接上传（适合单个脚本）

```bash
# 在本地执行
scp deploy/force-install-correct-versions.sh root@你的服务器IP:/var/www/my-fullstack-app/deploy/
```

---

## 推荐工作流程

1. **开发阶段**：在本地创建和测试脚本
2. **提交阶段**：提交到 Git 并推送到 Gitee
3. **部署阶段**：在服务器上拉取最新代码
4. **执行阶段**：运行脚本

## 快速同步命令（一键）

### 本地执行（提交并推送）

```bash
cd /path/to/my-fullstack-app
git add deploy/*.sh deploy/*.py && \
git commit -m "添加部署脚本" && \
git push gitee main && \
echo "✓ 已推送到 Gitee，请在服务器上执行: git pull gitee main"
```

### 服务器执行（拉取并运行）

```bash
cd /var/www/my-fullstack-app && \
git pull gitee main && \
bash deploy/force-install-correct-versions.sh
```

---

## 注意事项

1. **脚本权限**：确保脚本有执行权限 `chmod +x script.sh`
2. **路径检查**：脚本中的路径要正确（`/var/www/my-fullstack-app`）
3. **Git 远程**：确认 Gitee 远程仓库名称（可能是 `gitee`、`origin` 等）
4. **分支名称**：确认分支名称（可能是 `main`、`master` 等）

