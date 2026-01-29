<template>
  <nav class="navigation">
    <div class="nav-container">
      <div class="nav-logo">
        <router-link to="/" class="logo-link">AI产品</router-link>
      </div>
      <div class="nav-links">
        <router-link to="/" class="nav-link" :class="{ active: $route.path === '/' }">
          首页
        </router-link>
        <router-link to="/tools" class="nav-link" :class="{ active: $route.path === '/tools' }">
          工具
        </router-link>
      </div>
    </div>
  </nav>
</template>

<script setup>
// Navigation component
</script>

<style scoped>
.navigation {
  position: sticky;
  top: 0;
  z-index: 1000;
  background: rgba(10, 10, 10, 0.8);
  backdrop-filter: blur(10px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  padding: 0;
}

.nav-container {
  max-width: 1600px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 2rem;
}

.nav-logo .logo-link {
  font-size: 1.5rem;
  font-weight: 800;
  background: linear-gradient(135deg, #00d4ff 0%, #8a2be2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  text-decoration: none;
  transition: all 0.3s ease;
}

.nav-logo .logo-link:hover {
  text-shadow: 0 0 20px rgba(0, 212, 255, 0.5);
}

.nav-links {
  display: flex;
  gap: 2rem;
}

.nav-link {
  color: rgba(255, 255, 255, 0.7);
  text-decoration: none;
  font-size: 1rem;
  font-weight: 500;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  transition: all 0.3s ease;
  position: relative;
}

.nav-link:hover {
  color: #ffffff;
  background: rgba(255, 255, 255, 0.05);
}

.nav-link.active {
  color: #00d4ff;
  background: rgba(0, 212, 255, 0.1);
}

.nav-link.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 30px;
  height: 2px;
  background: linear-gradient(90deg, #00d4ff, #8a2be2);
  border-radius: 2px;
}

@media (max-width: 768px) {
  .nav-container {
    padding: 1rem;
  }
  
  .nav-links {
    gap: 1rem;
  }
  
  .nav-link {
    font-size: 0.9rem;
    padding: 0.4rem 0.8rem;
  }
}
</style>

