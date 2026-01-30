<template>
  <div class="admin-login-container">
    <div class="admin-login-card">
      <div class="admin-login-header">
        <h1 class="admin-login-title">管理员登录</h1>
        <p class="admin-login-subtitle">请使用管理员账号登录</p>
      </div>

      <form @submit.prevent="handleLogin" class="admin-login-form">
        <div class="form-group">
          <label for="username">用户名</label>
          <input id="username" v-model="username" type="text" placeholder="请输入管理员用户名" required :disabled="loading" />
        </div>

        <div class="form-group">
          <label for="password">密码</label>
          <input id="password" v-model="password" type="password" placeholder="请输入管理员密码" required :disabled="loading" />
        </div>

        <div v-if="error" class="error-message">
          {{ error }}
        </div>

        <button type="submit" class="submit-button" :disabled="loading">
          {{ loading ? '登录中...' : '登录' }}
        </button>
      </form>

      <div class="admin-login-footer">
        <p>
          <router-link to="/" class="link">返回首页</router-link>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth'

const router = useRouter()
const { login } = useAuth()
// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'

const username = ref('Admin')
const password = ref('')
const loading = ref(false)
const error = ref('')

const checkAdminExists = async () => {
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/check`)
    const data = await response.json()
    if (!data.exists) {
      // 如果admin不存在，跳转到setup页面
      router.push('/admin/setup')
    }
  } catch (e) {
    console.error('检查admin状态失败:', e)
  }
}

onMounted(() => {
  checkAdminExists()
})

const handleLogin = async () => {
  error.value = ''

  // 管理员登录不需要密码长度验证

  loading.value = true

  const result = await login(username.value, password.value)

  if (result.success) {
    // 登录成功后跳转到管理页面
    router.push('/admin')
  } else {
    // 将错误信息转换为中文
    let errorMsg = result.error || '登录失败，请检查用户名和密码'
    if (errorMsg.includes('Incorrect username or password')) {
      errorMsg = '用户名或密码错误'
    } else if (errorMsg.includes('Inactive user')) {
      errorMsg = '账号已被禁用'
    } else if (errorMsg.includes('Internal server error')) {
      errorMsg = '服务器错误，请稍后重试'
    }
    error.value = errorMsg
  }

  loading.value = false
}
</script>

<style scoped>
.admin-login-container {
  min-height: calc(100vh - 80px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem 1rem;
  background: #ffffff;
  background-image:
    radial-gradient(at 0% 0%, rgba(16, 185, 129, 0.03) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(5, 150, 105, 0.03) 0px, transparent 50%);
}

.admin-login-card {
  width: 100%;
  max-width: 400px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
  padding: 2rem;
}

.admin-login-header {
  text-align: center;
  margin-bottom: 2rem;
}

.admin-login-title {
  font-size: 2rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 0.5rem;
}

.admin-login-subtitle {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
}

.admin-login-form {
  margin-bottom: 1.5rem;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
}

.form-group input {
  width: 100%;
  padding: 0.75rem;
  font-size: 1rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  transition: all 0.2s;
  box-sizing: border-box;
}

.form-group input:focus {
  outline: none;
  border-color: #10b981;
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
}

.form-group input:disabled {
  background-color: #f9fafb;
  cursor: not-allowed;
}

.error-message {
  padding: 0.75rem;
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 8px;
  color: #dc2626;
  font-size: 0.875rem;
  margin-bottom: 1rem;
}

.submit-button {
  width: 100%;
  padding: 0.75rem;
  font-size: 1rem;
  font-weight: 600;
  color: #ffffff;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s;
}

.submit-button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.4);
}

.submit-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.admin-login-footer {
  text-align: center;
  padding-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
}

.admin-login-footer p {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
}

.admin-login-footer .link {
  color: #10b981;
  text-decoration: none;
  font-weight: 500;
}

.admin-login-footer .link:hover {
  text-decoration: underline;
}
</style>
