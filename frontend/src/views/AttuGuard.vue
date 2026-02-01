<template>
    <div class="attu-guard-container">
        <div v-if="checking" class="loading-state">
            <div class="spinner"></div>
            <p>正在验证权限...</p>
        </div>
        <div v-else-if="error" class="error-state">
            <p>{{ error }}</p>
            <button @click="redirectToLogin" class="btn-login">前往登录</button>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { token, user } from '../composables/useAuth'

const router = useRouter()
const checking = ref(true)
const error = ref('')

const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'

const checkAdminAuth = async () => {
    checking.value = true
    error.value = ''

    try {
        // 检查是否有 token
        if (!token.value) {
            error.value = '请先登录'
            checking.value = false
            setTimeout(() => {
                router.push('/admin/login')
            }, 1500)
            return
        }

        // 验证 token 并获取用户信息
        const response = await fetch(`${API_BASE_URL}/api/auth/me`, {
            headers: {
                'Authorization': `Bearer ${token.value}`,
            },
        })

        if (!response.ok) {
            error.value = '登录已过期，请重新登录'
            checking.value = false
            setTimeout(() => {
                router.push('/admin/login')
            }, 1500)
            return
        }

        const userData = await response.json()

        // 检查是否是管理员（这里假设所有已登录的用户都可以访问，或者可以根据实际需求添加角色检查）
        // 由于 Attu 是管理工具，我们要求用户必须已登录
        if (userData && userData.username) {
            // 验证通过，确保 Cookie 已设置，然后重定向到 Attu
            // 如果 Cookie 不存在，重新设置
            const cookies = document.cookie.split(';')
            const hasTokenCookie = cookies.some(cookie => cookie.trim().startsWith('token='))
            
            if (!hasTokenCookie && token.value) {
                // 设置 Cookie 用于 Nginx auth_request 验证
                document.cookie = `token=${token.value}; path=/; max-age=86400; SameSite=Lax`
            }
            
            // 等待一小段时间确保 Cookie 设置完成，然后重定向
            setTimeout(() => {
                window.location.href = '/attu/'
            }, 100)
        } else {
            error.value = '权限不足，需要管理员权限'
            checking.value = false
            setTimeout(() => {
                router.push('/admin/login')
            }, 1500)
        }
    } catch (err) {
        console.error('验证权限失败:', err)
        error.value = '验证权限失败，请重试'
        checking.value = false
        setTimeout(() => {
            router.push('/admin/login')
        }, 2000)
    }
}

const redirectToLogin = () => {
    router.push('/admin/login')
}

onMounted(() => {
    checkAdminAuth()
})
</script>

<style scoped>
.attu-guard-container {
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #f9fafb;
}

.loading-state,
.error-state {
    text-align: center;
    padding: 2rem;
}

.spinner {
    width: 40px;
    height: 40px;
    border: 4px solid #e5e7eb;
    border-top-color: #3b82f6;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    margin: 0 auto 1rem;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}

.loading-state p {
    color: #6b7280;
    font-size: 1rem;
    margin: 0;
}

.error-state p {
    color: #ef4444;
    font-size: 1rem;
    margin-bottom: 1.5rem;
}

.btn-login {
    padding: 0.75rem 1.5rem;
    background: #3b82f6;
    color: #ffffff;
    border: none;
    border-radius: 8px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: background 0.2s;
}

.btn-login:hover {
    background: #2563eb;
}
</style>
