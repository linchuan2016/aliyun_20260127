<template>
  <a 
    v-if="product.official_url" 
    :href="product.official_url" 
    target="_blank" 
    rel="noopener noreferrer"
    class="product-card"
  >
    <div class="product-image">
      <img :src="getIconUrl(product)" :alt="product.title" @error="handleImageError" />
    </div>
    <div class="product-content">
      <h2 class="product-title">{{ product.title }}</h2>
      <p class="product-description">{{ product.description }}</p>
      <div class="product-features" v-if="product.features && product.features.length > 0">
        <ul>
          <li v-for="(feature, index) in product.features.slice(0, 2)" :key="index">{{ feature }}</li>
        </ul>
      </div>
    </div>
  </a>
  <div v-else class="product-card">
    <div class="product-image">
      <img :src="getIconUrl(product)" :alt="product.title" @error="handleImageError" />
    </div>
    <div class="product-content">
      <h2 class="product-title">{{ product.title }}</h2>
      <p class="product-description">{{ product.description }}</p>
      <div class="product-features" v-if="product.features && product.features.length > 0">
        <ul>
          <li v-for="(feature, index) in product.features.slice(0, 2)" :key="index">{{ feature }}</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import '../styles/ProductCard.css'

defineProps({
  product: {
    type: Object,
    required: true
  }
})

const handleImageError = (event) => {
  // 如果图标加载失败，使用占位图标
  const placeholderUrl = '/icons/placeholder.svg'
  if (event.target.src !== placeholderUrl && !event.target.src.includes('placeholder')) {
    console.warn('图标加载失败，使用占位图标:', event.target.src)
    event.target.src = placeholderUrl
  }
}

// 生成产品图标 URL 的辅助函数
const getIconUrl = (product) => {
  if (!product || !product.image_url) {
    return '/icons/placeholder.svg'
  }
  // 如果是外部 URL，直接返回
  if (product.image_url.startsWith('http')) {
    return product.image_url
  }
  // 如果是相对路径，返回
  return product.image_url
}
</script>
