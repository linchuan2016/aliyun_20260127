import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'

// 全局状态
const token = ref(localStorage.getItem('token') || null)
const user = ref(JSON.parse(localStorage.getItem('user') || 'null'))

// 计算属性
const isAuthenticated = computed(() => !!token.value)

// 登录
export function useAuth() {
  const router = useRouter()

  const login = async (username, password) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/auth/login-json`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
      })

      if (!response.ok) {
        let errorMessage = '登录失败'
        try {
          const error = await response.json()
          errorMessage = error.detail || errorMessage
        } catch (e) {
          errorMessage = `服务器错误: ${response.status} ${response.statusText}`
        }
        throw new Error(errorMessage)
      }

      const data = await response.json()
      token.value = data.access_token
      user.value = data.user
      
      // 保存到 localStorage
      localStorage.setItem('token', data.access_token)
      localStorage.setItem('user', JSON.stringify(data.user))
      
      // 同时设置 Cookie，用于 Nginx auth_request 验证
      document.cookie = `token=${data.access_token}; path=/; max-age=86400; SameSite=Lax`
      
      return { success: true }
    } catch (error) {
      // 处理网络错误
      if (error instanceof TypeError && error.message === 'Failed to fetch') {
        return { success: false, error: '无法连接到服务器，请检查后端服务是否运行' }
      }
      return { success: false, error: error.message }
    }
  }

  // 注册
  const register = async (username, email, password) => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, email, password }),
      })

      if (!response.ok) {
        let errorMessage = '注册失败'
        try {
          const error = await response.json()
          errorMessage = error.detail || errorMessage
        } catch (e) {
          errorMessage = `服务器错误: ${response.status} ${response.statusText}`
        }
        throw new Error(errorMessage)
      }

      const data = await response.json()
      return { success: true, user: data }
    } catch (error) {
      // 处理网络错误
      if (error.message === 'Failed to fetch' || error.name === 'TypeError') {
        return { success: false, error: '无法连接到服务器，请检查后端服务是否运行' }
      }
      return { success: false, error: error.message }
    }
  }

  // 登出
  const logout = () => {
    token.value = null
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    // 清除 Cookie
    document.cookie = 'token=; path=/; max-age=0'
    router.push('/')
  }

  // 获取当前用户信息
  const getCurrentUser = async () => {
    if (!token.value) return null
    
    try {
      const response = await fetch(`${API_BASE_URL}/api/auth/me`, {
        headers: {
          'Authorization': `Bearer ${token.value}`,
        },
      })

      if (!response.ok) {
        throw new Error('获取用户信息失败')
      }

      const data = await response.json()
      user.value = data
      localStorage.setItem('user', JSON.stringify(data))
      return data
    } catch (error) {
      logout()
      return null
    }
  }

  return {
    token,
    user,
    isAuthenticated,
    login,
    register,
    logout,
    getCurrentUser,
  }
}

// 导出状态（用于在组件外访问）
export { token, user, isAuthenticated }

