# 网站配置文档

## 网站地址

### 本地开发环境

- **前端地址**: http://localhost:5173
- **后端API地址**: http://127.0.0.1:8000
- **API文档**: http://127.0.0.1:8000/docs

### 生产环境（阿里云）

- **网站地址**: https://linchuan.tech
- **后端API地址**: https://linchuan.tech/api
- **API文档**: https://linchuan.tech/docs

---

## 用户功能

### 用户注册和登录

- **注册页面**: `/register`
- **登录页面**: `/login`
- **注册成功页面**: `/register/success`

**功能说明**:
- 用户可以注册账号（用户名、邮箱、密码）
- 注册成功后可以登录
- 登录后可以访问个人相关功能

---

## 管理员功能

### 管理员登录

- **管理员登录地址**: `/admin/login`
- **完整URL（本地）**: http://localhost:5173/admin/login
- **完整URL（生产）**: https://linchuan.tech/admin/login

### 管理员后台

- **管理员后台地址**: `/admin`
- **完整URL（本地）**: http://localhost:5173/admin
- **完整URL（生产）**: https://linchuan.tech/admin

**功能说明**:
- 管理员登录页面与用户登录页面分离
- 管理员登录后可以访问用户管理后台
- 管理员可以查看所有用户列表
- 管理员可以启用/禁用用户
- 管理员可以删除用户（不能删除自己）

---

## 初始管理员账号

### 默认管理员账号

- **用户名**: `Admin`
- **密码**: `1990716zzz`
- **邮箱**: `admin@example.com`

**重要提示**:
- 首次部署后请立即登录并修改密码
- 建议在生产环境中创建新的管理员账号并删除默认账号
- 管理员账号密码请妥善保管，不要泄露

---

## 其他页面地址

### 主要页面

- **首页**: `/`
- **工具页面**: `/tools`
  - 日历: `/tools/calendar`
  - 便签: `/tools/notes`
- **RAG页面**: `/rag`

### RAG产品链接

- **Milvus**: https://milvus.io
- **PGVector**: https://github.com/pgvector/pgvector
- **Qdrant**: https://qdrant.tech
- **MyScale**: https://myscale.com

---

## API端点

### 认证相关

- `POST /api/auth/register` - 用户注册
- `POST /api/auth/login-json` - 用户登录（JSON格式）
- `POST /api/auth/login` - 用户登录（OAuth2格式）
- `GET /api/auth/me` - 获取当前用户信息

### 管理员相关（需要登录）

- `GET /api/admin/users` - 获取所有用户列表
- `GET /api/admin/users/{user_id}` - 获取单个用户信息
- `DELETE /api/admin/users/{user_id}` - 删除用户
- `PATCH /api/admin/users/{user_id}/status` - 更新用户状态

### 产品相关

- `GET /api/products` - 获取所有产品列表
- `GET /api/products/{product_name}` - 获取单个产品信息

---

## 启动服务

### 本地开发环境

**Windows**:
```powershell
# 使用启动脚本
.\start-local.ps1

# 或使用批处理文件
.\start-local.bat
```

**手动启动**:
```powershell
# 1. 启动后端服务
cd backend
..\venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8000

# 2. 启动前端服务（新终端）
cd frontend
npm run dev
```

### 生产环境（阿里云）

```bash
# 使用systemd服务
sudo systemctl start my-fullstack-app-ssl
sudo systemctl enable my-fullstack-app-ssl

# 查看服务状态
sudo systemctl status my-fullstack-app-ssl

# 查看日志
sudo journalctl -u my-fullstack-app-ssl -f
```

---

## 数据库

### 本地开发

- **数据库类型**: SQLite
- **数据库文件**: `backend/products.db`
- **初始化**: 运行 `backend/init_db.py`

### 生产环境

- **数据库类型**: MySQL
- **配置**: 通过环境变量配置（`.env`文件）

---

## 安全注意事项

1. **管理员账号**: 请妥善保管管理员账号密码，不要泄露
2. **HTTPS**: 生产环境必须使用HTTPS
3. **CORS**: 已配置CORS，仅允许指定域名访问
4. **密码加密**: 使用bcrypt加密存储密码
5. **JWT Token**: 使用JWT token进行身份验证，token有效期可配置

---

## 更新日志

- **2024-01-XX**: 添加用户注册和登录功能
- **2024-01-XX**: 添加管理员后台管理功能
- **2024-01-XX**: 分离管理员登录页面和用户登录页面

---

## 联系方式

如有问题，请联系系统管理员。

