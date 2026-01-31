<template>
  <nav class="navigation">
    <div class="nav-container">
      <div class="nav-left">
        <router-link to="/" class="logo-link">
          <img src="/icons/logo-l.svg" alt="Logo" class="logo-icon" />
        </router-link>
        <div class="nav-links">
          <router-link to="/" class="nav-link" :class="{ active: $route.path === '/' }">
            首页
          </router-link>
          <router-link to="/rag" class="nav-link" :class="{ active: $route.path === '/rag' }">
            RAG
          </router-link>
          <router-link to="/blog" class="nav-link" :class="{ active: $route.path === '/blog' }">
            Blog
          </router-link>
          <router-link to="/book" class="nav-link" :class="{ active: $route.path === '/book' }">
            Book
          </router-link>
        </div>
      </div>
      <div class="nav-right">
        <div class="auth-buttons">
          <template v-if="isAuthenticated">
            <router-link to="/my" class="auth-button my-button">我的</router-link>
            <span class="user-info">欢迎, {{ user?.username }}!</span>
            <button @click="handleLogout" class="auth-button logout-button">退出</button>
          </template>
          <template v-else>
            <router-link to="/login" class="auth-button login-button">登录</router-link>
            <router-link to="/register" class="auth-button register-button">注册</router-link>
          </template>
        </div>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { useAuth } from '../composables/useAuth'

const { isAuthenticated, user, logout } = useAuth()

const handleLogout = () => {
  logout()
}
</script>

<style scoped>
.navigation {
  position: sticky;
  top: 0;
  z-index: 1000;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid #e5e7eb;
  padding: 0;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.nav-container {
  max-width: 1600px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 2rem;
}

.nav-left {
  display: flex;
  align-items: center;
  gap: 2rem;
}

.nav-right {
  display: flex;
  align-items: center;
  gap: 2rem;
}

.logo-link {
  display: flex;
  align-items: center;
  text-decoration: none;
  transition: all 0.3s ease;
}

.logo-icon {
  width: 32px;
  height: 32px;
  transition: transform 0.3s ease;
}

.logo-link:hover .logo-icon {
  transform: scale(1.1);
}

.nav-links {
  display: flex;
  gap: 2rem;
}

.nav-link {
  color: #6b7280;
  text-decoration: none;
  font-size: 1rem;
  font-weight: 500;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  transition: all 0.3s ease;
  position: relative;
}

.nav-link:hover {
  color: #111827;
  background: #f9fafb;
}

.nav-link.active {
  color: #3b82f6;
  background: rgba(59, 130, 246, 0.1);
}

.nav-link.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 30px;
  height: 2px;
  background: linear-gradient(90deg, #3b82f6, #8b5cf6);
  border-radius: 2px;
}

.auth-buttons {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.user-info {
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 500;
}

.auth-button {
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  font-weight: 500;
  border-radius: 8px;
  text-decoration: none;
  transition: all 0.3s ease;
  border: none;
  cursor: pointer;
}

.login-button {
  color: #6b7280;
  background: transparent;
  border: 1px solid transparent;
}

.login-button:hover {
  color: #111827;
  background: #f9fafb;
}

.register-button {
  color: #6b7280;
  background: transparent;
  border: 1px solid transparent;
}

.register-button:hover {
  color: #111827;
  background: #f9fafb;
}

.admin-button {
  color: #3b82f6;
  background: rgba(59, 130, 246, 0.1);
}

.admin-button:hover {
  color: #2563eb;
  background: rgba(59, 130, 246, 0.2);
}

.my-button {
  color: #6b7280;
  background: transparent;
  border: 1px solid transparent;
}

.my-button:hover {
  color: #111827;
  background: #f9fafb;
}

.logout-button {
  color: #6b7280;
  background: #f9fafb;
}

.logout-button:hover {
  color: #111827;
  background: #f3f4f6;
}

@media (max-width: 768px) {
  .nav-container {
    padding: 1rem;
    flex-wrap: wrap;
  }

  .nav-left {
    gap: 1rem;
    flex-wrap: wrap;
  }

  .nav-right {
    gap: 1rem;
  }

  .nav-links {
    gap: 0.5rem;
    flex-wrap: wrap;
  }

  .nav-link {
    font-size: 0.9rem;
    padding: 0.4rem 0.8rem;
  }

  .auth-buttons {
    gap: 0.5rem;
  }

  .auth-button {
    padding: 0.4rem 0.8rem;
    font-size: 0.8rem;
  }

  .user-info {
    display: none;
  }
}
</style>
