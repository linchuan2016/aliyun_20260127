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
// 强制只使用本地路径，拒绝所有外部URL以避免依赖VPN
const getIconUrl = (product) => {
  if (!product || !product.image_url) {
    return '/icons/placeholder.svg'
  }
  // 如果包含外部URL（http/https），根据产品名称生成本地路径
  if (product.image_url.startsWith('http')) {
    // 根据产品名称生成本地图标路径
    const productName = product.name || product.title?.toLowerCase().replace(/\s+/g, '')
    if (productName) {
      // 处理特殊名称映射
      const iconMap = {
        'notebooklm': 'notebooklm',
        'huggingface': 'huggingface',
        'toolify.ai': 'toolify',
        'aibase': 'aibase',
        'futurepedia': 'futurepedia'
      }
      const iconName = iconMap[productName] || productName
      return `/icons/${iconName}.png`
    }
    return '/icons/placeholder.svg'
  }
  // 如果是相对路径，直接返回
  return product.image_url
}
</script>
