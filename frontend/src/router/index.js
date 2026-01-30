import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Tools from '../views/Tools.vue'
import CalendarPage from '../views/CalendarPage.vue'
import NotesPage from '../views/NotesPage.vue'
import RAG from '../views/RAG.vue'
import Blog from '../views/Blog.vue'
import Login from '../views/Login.vue'
import Register from '../views/Register.vue'
import RegisterSuccess from '../views/RegisterSuccess.vue'
import AdminLogin from '../views/AdminLogin.vue'
import AdminSetup from '../views/AdminSetup.vue'
import Admin from '../views/Admin.vue'
import AdminArticles from '../views/AdminArticles.vue'
import My from '../views/My.vue'
import { token } from '../composables/useAuth'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/tools',
    name: 'Tools',
    component: Tools
  },
  {
    path: '/tools/calendar',
    name: 'CalendarPage',
    component: CalendarPage
  },
  {
    path: '/tools/notes',
    name: 'NotesPage',
    component: NotesPage
  },
  {
    path: '/rag',
    name: 'RAG',
    component: RAG
  },
  {
    path: '/blog',
    name: 'Blog',
    component: Blog
  },
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/register',
    name: 'Register',
    component: Register
  },
  {
    path: '/register/success',
    name: 'RegisterSuccess',
    component: RegisterSuccess
  },
  {
    path: '/admin/setup',
    name: 'AdminSetup',
    component: AdminSetup
  },
  {
    path: '/admin/login',
    name: 'AdminLogin',
    component: AdminLogin
  },
  {
    path: '/admin',
    name: 'Admin',
    component: Admin,
    meta: { requiresAuth: true }
  },
  {
    path: '/admin/articles',
    name: 'AdminArticles',
    component: AdminArticles,
    meta: { requiresAuth: true }
  },
  {
    path: '/my',
    name: 'My',
    component: My,
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 路由守卫：检查需要登录的页面
router.beforeEach(async (to, from, next) => {
  // 如果是管理员相关页面，先检查admin是否存在
  if (to.path.startsWith('/admin')) {
    try {
      const response = await fetch('http://127.0.0.1:8000/api/admin/check')
      const data = await response.json()
      if (!data.exists) {
        // 如果admin不存在，且不是访问setup页面，则跳转到setup页面
        if (to.path !== '/admin/setup') {
          next('/admin/setup')
          return
        }
      } else {
        // 如果admin存在，且访问的是setup页面，则跳转到登录页面
        if (to.path === '/admin/setup') {
          next('/admin/login')
          return
        }
      }
    } catch (e) {
      console.error('检查admin状态失败:', e)
      // 如果检查失败，且不是setup页面，默认跳转到登录页面
      if (to.path !== '/admin/setup' && to.meta.requiresAuth) {
        next('/admin/login')
        return
      }
    }
  }

  // 检查需要登录的页面
  if (to.meta.requiresAuth) {
    if (!token.value) {
      // 如果是管理员页面，跳转到管理员登录页面
      if (to.path.startsWith('/admin')) {
        next('/admin/login')
      } else {
        // 其他需要登录的页面，跳转到用户登录页面
        next('/login')
      }
    } else {
      next()
    }
  } else {
    next()
  }
})

export default router

