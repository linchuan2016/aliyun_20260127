<template>
  <div class="success-container">
    <div class="success-card">
      <div class="success-icon">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="64"
          height="64"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          stroke-width="2"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
          <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
      </div>

      <h1 class="success-title">注册成功！</h1>
      <p class="success-message">
        欢迎，<strong>{{ username }}</strong>！您的账号已成功创建。
      </p>

      <div class="success-actions">
        <router-link to="/login" class="button button-primary">
          立即登录
        </router-link>
        <router-link to="/" class="button button-secondary">
          返回首页
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()
const username = ref('')

onMounted(() => {
  username.value = route.query.username || '用户'
})
</script>

<style scoped>
.success-container {
  min-height: calc(100vh - 80px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 2rem 1rem;
  background: #ffffff;
  background-image:
    radial-gradient(at 0% 0%, rgba(59, 130, 246, 0.03) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(139, 92, 246, 0.03) 0px, transparent 50%);
}

.success-card {
  width: 100%;
  max-width: 500px;
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
  padding: 3rem 2rem;
  text-align: center;
}

.success-icon {
  width: 80px;
  height: 80px;
  margin: 0 auto 1.5rem;
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ffffff;
}

.success-title {
  font-size: 2rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 1rem;
}

.success-message {
  font-size: 1rem;
  color: #6b7280;
  margin-bottom: 2rem;
  line-height: 1.6;
}

.success-message strong {
  color: #3b82f6;
  font-weight: 600;
}

.success-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}

.button {
  padding: 0.75rem 1.5rem;
  font-size: 1rem;
  font-weight: 600;
  border-radius: 8px;
  text-decoration: none;
  transition: all 0.3s;
  display: inline-block;
}

.button-primary {
  color: #ffffff;
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
}

.button-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4);
}

.button-secondary {
  color: #374151;
  background: #f9fafb;
  border: 1px solid #e5e7eb;
}

.button-secondary:hover {
  background: #f3f4f6;
  border-color: #d1d5db;
}

@media (max-width: 640px) {
  .success-actions {
    flex-direction: column;
  }

  .button {
    width: 100%;
  }
}
</style>

