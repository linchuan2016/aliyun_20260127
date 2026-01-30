<template>
  <div class="admin-container">
    <div class="admin-header">
      <h1 class="admin-title">后台管理</h1>
      <div class="admin-tabs">
        <router-link to="/admin" class="admin-tab" :class="{ active: $route.path === '/admin' }">
          用户管理
        </router-link>
        <router-link to="/admin/articles" class="admin-tab" :class="{ active: $route.path === '/admin/articles' }">
          文章管理
        </router-link>
      </div>
    </div>

    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>加载中...</p>
    </div>

    <div v-else-if="error" class="error-message">
      {{ error }}
    </div>

    <div v-else class="admin-content">
      <div class="stats-bar">
        <div class="stat-card">
          <div class="stat-value">{{ total }}</div>
          <div class="stat-label">总用户数</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ activeCount }}</div>
          <div class="stat-label">活跃用户</div>
        </div>
        <div class="stat-card">
          <div class="stat-value">{{ inactiveCount }}</div>
          <div class="stat-label">禁用用户</div>
        </div>
      </div>

      <div class="users-table-container">
        <table class="users-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>用户名</th>
              <th>邮箱</th>
              <th>状态</th>
              <th>注册时间</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="user in users" :key="user.id" :class="{ 'inactive': !user.is_active }">
              <td>{{ user.id }}</td>
              <td>{{ user.username }}</td>
              <td>{{ user.email }}</td>
              <td>
                <span :class="['status-badge', user.is_active ? 'active' : 'inactive']">
                  {{ user.is_active ? '活跃' : '禁用' }}
                </span>
              </td>
              <td>{{ formatDate(user.created_at) }}</td>
              <td class="actions">
                <button
                  @click="toggleUserStatus(user)"
                  :class="['btn', 'btn-sm', user.is_active ? 'btn-warning' : 'btn-success']"
                  :disabled="user.id === currentUser?.id"
                >
                  {{ user.is_active ? '禁用' : '启用' }}
                </button>
                <button
                  @click="deleteUser(user)"
                  class="btn btn-sm btn-danger"
                  :disabled="user.id === currentUser?.id"
                >
                  删除
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useAuth } from '../composables/useAuth'

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'
const { user: currentUser, token } = useAuth()

const users = ref([])
const total = ref(0)
const loading = ref(true)
const error = ref('')

const activeCount = computed(() => {
  return users.value.filter(u => u.is_active).length
})

const inactiveCount = computed(() => {
  return users.value.filter(u => !u.is_active).length
})

const fetchUsers = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/users`, {
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('请先登录')
      }
      throw new Error('获取用户列表失败')
    }

    const data = await response.json()
    users.value = data.users
    total.value = data.total
  } catch (err) {
    error.value = err.message || '加载用户列表失败'
  } finally {
    loading.value = false
  }
}

const toggleUserStatus = async (user) => {
  if (user.id === currentUser.value?.id) {
    alert('不能修改自己的状态')
    return
  }

  if (!confirm(`确定要${user.is_active ? '禁用' : '启用'}用户 "${user.username}" 吗？`)) {
    return
  }

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/users/${user.id}/status?is_active=${!user.is_active}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      throw new Error('更新用户状态失败')
    }

    await fetchUsers()
  } catch (err) {
    alert(err.message || '操作失败')
  }
}

const deleteUser = async (user) => {
  if (user.id === currentUser.value?.id) {
    alert('不能删除自己的账号')
    return
  }

  if (!confirm(`确定要删除用户 "${user.username}" 吗？此操作不可恢复！`)) {
    return
  }

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/users/${user.id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      throw new Error('删除用户失败')
    }

    await fetchUsers()
  } catch (err) {
    alert(err.message || '删除失败')
  }
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleString('zh-CN')
}

onMounted(() => {
  if (!token.value) {
    // 如果没有token，路由守卫应该已经跳转到登录页
    // 但为了安全，这里也做一次检查
    error.value = '请先登录'
    loading.value = false
    return
  }
  fetchUsers()
})
</script>

<style scoped>
.admin-container {
  min-height: calc(100vh - 80px);
  padding: 2rem 1rem;
  background: #ffffff;
  background-image:
    radial-gradient(at 0% 0%, rgba(59, 130, 246, 0.03) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(139, 92, 246, 0.03) 0px, transparent 50%);
}

.admin-header {
  max-width: 1600px;
  margin: 0 auto 2rem;
}

.admin-title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 0.5rem;
}

.admin-subtitle {
  font-size: 1rem;
  color: #6b7280;
}

.admin-tabs {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
  border-bottom: 2px solid #e5e7eb;
}

.admin-tab {
  padding: 0.75rem 1.5rem;
  text-decoration: none;
  color: #6b7280;
  font-weight: 500;
  border-bottom: 2px solid transparent;
  margin-bottom: -2px;
  transition: all 0.2s;
}

.admin-tab:hover {
  color: #111827;
}

.admin-tab.active {
  color: #3b82f6;
  border-bottom-color: #3b82f6;
}

.loading {
  text-align: center;
  padding: 3rem;
}

.spinner {
  border: 3px solid rgba(0, 0, 0, 0.1);
  border-top-color: #3b82f6;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-message {
  max-width: 1600px;
  margin: 0 auto;
  padding: 1rem;
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 8px;
  color: #dc2626;
  text-align: center;
}

.admin-content {
  max-width: 1600px;
  margin: 0 auto;
}

.stats-bar {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 1.5rem;
  text-align: center;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: #3b82f6;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 0.875rem;
  color: #6b7280;
}

.users-table-container {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.users-table {
  width: 100%;
  border-collapse: collapse;
}

.users-table thead {
  background: #f9fafb;
}

.users-table th {
  padding: 1rem;
  text-align: left;
  font-weight: 600;
  color: #374151;
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 2px solid #e5e7eb;
}

.users-table td {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  color: #111827;
}

.users-table tbody tr:hover {
  background: #f9fafb;
}

.users-table tbody tr.inactive {
  opacity: 0.6;
}

.status-badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
}

.status-badge.active {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.inactive {
  background: #fee2e2;
  color: #991b1b;
}

.actions {
  display: flex;
  gap: 0.5rem;
}

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-sm {
  padding: 0.375rem 0.75rem;
  font-size: 0.75rem;
}

.btn-success {
  background: #10b981;
  color: #ffffff;
}

.btn-success:hover:not(:disabled) {
  background: #059669;
}

.btn-warning {
  background: #f59e0b;
  color: #ffffff;
}

.btn-warning:hover:not(:disabled) {
  background: #d97706;
}

.btn-danger {
  background: #ef4444;
  color: #ffffff;
}

.btn-danger:hover:not(:disabled) {
  background: #dc2626;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .users-table-container {
    overflow-x: auto;
  }

  .users-table {
    min-width: 800px;
  }

  .stats-bar {
    grid-template-columns: 1fr;
  }
}
</style>

