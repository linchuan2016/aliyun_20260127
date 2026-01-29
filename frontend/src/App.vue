<script setup>
import { ref, onMounted } from 'vue'
import ProductCard from './components/ProductCard.vue'

const products = ref([])
const loading = ref(true)
const error = ref(null)

// 页面加载时向后端请求产品数据
onMounted(async () => {
  try {
    loading.value = true
    // 使用相对路径，通过 Nginx（生产环境）或 Vite 代理（本地开发）访问后端
    const url = '/api/products';

    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    products.value = data.products || []
    error.value = null
  } catch (err) {
    error.value = "无法连接到后端！"
    console.error('Error fetching products:', err)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="app-container">
    <!-- 头部 -->
    <header class="app-header">
      <h1 class="app-title">AI产品</h1>
      <p class="app-subtitle">AI网站快捷方式</p>
    </header>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>加载中...</p>
    </div>

    <!-- 错误状态 -->
    <div v-else-if="error" class="error">
      <p>{{ error }}</p>
    </div>

    <!-- 产品列表 -->
    <div v-else-if="products.length > 0" class="products-container">
      <ProductCard v-for="product in products" :key="product.id" :product="product" />
    </div>

    <!-- 空状态 -->
    <div v-else class="empty">
      <p>暂无产品数据</p>
    </div>
  </div>
</template>

<style scoped>
.app-container {
  min-height: 100vh;
  background: #0a0a0a;
  background-image:
    radial-gradient(at 0% 0%, rgba(0, 212, 255, 0.1) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(138, 43, 226, 0.1) 0px, transparent 50%);
  padding: 2rem 1rem;
  position: relative;
  overflow-x: hidden;
}

.app-container::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background:
    linear-gradient(180deg, transparent 0%, rgba(0, 212, 255, 0.03) 100%);
  pointer-events: none;
}

.app-header {
  text-align: center;
  margin-bottom: 2rem;
  padding: 2rem 0;
  position: relative;
  z-index: 1;
}

.app-title {
  font-size: 3rem;
  font-weight: 800;
  background: linear-gradient(135deg, #00d4ff 0%, #8a2be2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 0.5rem;
  letter-spacing: -0.02em;
  text-shadow: 0 0 30px rgba(0, 212, 255, 0.3);
}

.app-subtitle {
  font-size: 1rem;
  color: rgba(255, 255, 255, 0.6);
  margin: 0;
  font-weight: 300;
}

.products-container {
  max-width: 1600px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.75rem;
  position: relative;
  z-index: 1;
}

@media (min-width: 640px) {
  .products-container {
    grid-template-columns: repeat(3, 1fr);
    gap: 0.75rem;
  }
}

@media (min-width: 768px) {
  .products-container {
    grid-template-columns: repeat(4, 1fr);
    gap: 1rem;
  }
}

@media (min-width: 1024px) {
  .products-container {
    grid-template-columns: repeat(4, 1fr);
    gap: 1rem;
  }
}

@media (min-width: 1280px) {
  .products-container {
    grid-template-columns: repeat(4, 1fr);
    gap: 1.25rem;
  }
}

.loading,
.error,
.empty {
  text-align: center;
  padding: 3rem;
  font-size: 1.25rem;
  color: rgba(255, 255, 255, 0.7);
}

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(255, 255, 255, 0.1);
  border-top-color: #00d4ff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error {
  color: #ff6b6b;
}

.empty {
  color: rgba(255, 255, 255, 0.5);
}
</style>
