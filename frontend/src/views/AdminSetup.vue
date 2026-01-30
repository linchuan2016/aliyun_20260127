<template>
  <div class="admin-setup-container">
    <div class="admin-setup-card">
      <div class="admin-setup-header">
        <h1 class="admin-setup-title">初始化管理员账号</h1>
        <p class="admin-setup-subtitle">首次使用，请设置管理员密码</p>
      </div>

      <form @submit.prevent="handleSetup" class="admin-setup-form">
        <div class="form-group">
          <label for="password">管理员密码</label>
          <input
            id="password"
            v-model="password"
            type="password"
            placeholder="请输入管理员密码"
            required
            :disabled="loading"
          />
        </div>

        <div class="form-group">
          <label for="confirmPassword">确认密码</label>
          <input
            id="confirmPassword"
            v-model="confirmPassword"
            type="password"
            placeholder="请再次输入密码"
            required
            :disabled="loading"
          />
        </div>

        <div v-if="error" class="error-message">
          {{ error }}
        </div>

        <div v-if="success" class="success-message">
          {{ success }}
        </div>

        <button type="submit" class="submit-button" :disabled="loading">
          {{ loading ? '设置中...' : '设置密码' }}
        </button>
      </form>

      <div class="admin-setup-footer">
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

const router = useRouter()
const API_BASE_URL = 'http://127.0.0.1:8000'

const password = ref('')
const confirmPassword = ref('')
const loading = ref(false)
const error = ref('')
const success = ref('')

const checkAdminExists = async () => {
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/check`)
    const data = await response.json()
    if (data.exists) {
      // 如果admin已存在，跳转到登录页面
      router.push('/admin/login')
    }
  } catch (e) {
    console.error('检查admin状态失败:', e)
  }
}

onMounted(() => {
  checkAdminExists()
})

const handleSetup = async () => {
  error.value = ''
  success.value = ''

  // 验证密码
  if (password.value !== confirmPassword.value) {
    error.value = '两次输入的密码不一致'
    return
  }

  if (!password.value) {
    error.value = '请输入密码'
    return
  }

  loading.value = true

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/setup`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ password: password.value }),
    })

    if (!response.ok) {
      const errorData = await response.json()
      error.value = errorData.detail || '设置失败，请重试'
      loading.value = false
      return
    }

    success.value = '管理员密码设置成功！正在跳转到登录页面...'
    
    // 等待2秒后跳转到登录页面
    setTimeout(() => {
      router.push('/admin/login')
    }, 2000)
  } catch (e) {
    error.value = '设置失败，请检查网络连接'
    loading.value = false
  }
}
</script>

<style scoped>
.admin-setup-container {
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

.admin-setup-card {
  width: 100%;
  max-width: 400px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
  padding: 2rem;
}

.admin-setup-header {
  text-align: center;
  margin-bottom: 2rem;
}

.admin-setup-title {
  font-size: 2rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 0.5rem;
}

.admin-setup-subtitle {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
}

.admin-setup-form {
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

.success-message {
  padding: 0.75rem;
  background-color: #f0fdf4;
  border: 1px solid #86efac;
  border-radius: 8px;
  color: #16a34a;
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

.admin-setup-footer {
  text-align: center;
  padding-top: 1.5rem;
  border-top: 1px solid #e5e7eb;
}

.admin-setup-footer p {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
}

.admin-setup-footer .link {
  color: #10b981;
  text-decoration: none;
  font-weight: 500;
}

.admin-setup-footer .link:hover {
  text-decoration: underline;
}
</style>

