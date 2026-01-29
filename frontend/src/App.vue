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
      <h1 class="app-title">产品展示</h1>
      <p class="app-subtitle">探索我们的创新产品</p>
    </header>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading">
      <p>加载中...</p>
    </div>

    <!-- 错误状态 -->
    <div v-else-if="error" class="error">
      <p>{{ error }}</p>
    </div>

    <!-- 产品列表 -->
    <div v-else-if="products.length > 0" class="products-container">
      <ProductCard 
        v-for="product in products" 
        :key="product.id" 
        :product="product" 
      />
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
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  padding: 2rem 1rem;
}

.app-header {
  text-align: center;
  margin-bottom: 3rem;
  padding: 2rem 0;
}

.app-title {
  font-size: 3rem;
  font-weight: 700;
  color: #2c3e50;
  margin-bottom: 0.5rem;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.1);
}

.app-subtitle {
  font-size: 1.25rem;
  color: #666;
  margin: 0;
}

.products-container {
  max-width: 1200px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: 1fr;
  gap: 2rem;
}

@media (min-width: 768px) {
  .products-container {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .products-container {
    grid-template-columns: repeat(3, 1fr);
  }
}

.loading,
.error,
.empty {
  text-align: center;
  padding: 3rem;
  font-size: 1.25rem;
  color: #666;
}

.error {
  color: #e74c3c;
}
</style>




