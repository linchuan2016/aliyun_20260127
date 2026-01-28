<template>
  <div class="product-card">
    <div class="product-image">
      <img :src="product.image_url || '/vite.svg'" :alt="product.title" />
    </div>
    <div class="product-content">
      <h2 class="product-title">{{ product.title }}</h2>
      <p class="product-description">{{ product.description }}</p>
      <div class="product-features" v-if="product.features && product.features.length > 0">
        <h3>主要特性：</h3>
        <ul>
          <li v-for="(feature, index) in product.features" :key="index">{{ feature }}</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  product: {
    type: Object,
    required: true
  }
})
</script>

<style scoped>
.product-card {
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  margin-bottom: 2rem;
}

.product-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.15);
}

.product-image {
  width: 100%;
  height: 250px;
  overflow: hidden;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}

.product-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.product-content {
  padding: 2rem;
}

.product-title {
  font-size: 1.75rem;
  font-weight: 700;
  color: #2c3e50;
  margin-bottom: 1rem;
}

.product-description {
  font-size: 1rem;
  line-height: 1.6;
  color: #555;
  margin-bottom: 1.5rem;
}

.product-features {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #eee;
}

.product-features h3 {
  font-size: 1.1rem;
  font-weight: 600;
  color: #42b983;
  margin-bottom: 0.75rem;
}

.product-features ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.product-features li {
  padding: 0.5rem 0;
  padding-left: 1.5rem;
  position: relative;
  color: #666;
  line-height: 1.5;
}

.product-features li::before {
  content: "✓";
  position: absolute;
  left: 0;
  color: #42b983;
  font-weight: bold;
}
</style>

