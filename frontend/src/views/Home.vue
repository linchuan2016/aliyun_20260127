<script setup>
import { ref, onMounted } from 'vue'
import ProductCard from '../components/ProductCard.vue'
import '../styles/App.css'

const products = ref([])
const loading = ref(true)
const error = ref(null)

// 页面加载时向后端请求产品数据
onMounted(async () => {
  try {
    loading.value = true
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
