<script setup>
import { useRouter } from 'vue-router'

const router = useRouter()

const tools = [
  {
    id: 'calendar',
    title: '万年历',
    description: '查看日期、农历、节气等信息',
    icon: '📅',
    route: '/tools/calendar'
  },
  {
    id: 'notes',
    title: '便签',
    description: '记录想法和待办事项',
    icon: '📝',
    route: '/tools/notes'
  }
]

const goToTool = (route) => {
  router.push(route)
}
</script>

<template>
  <div class="tools-container">
    <header class="tools-header">
      <h1 class="tools-title">实用工具</h1>
      <p class="tools-subtitle">便捷的在线工具集合</p>
    </header>

    <div class="tools-grid">
      <div
        v-for="tool in tools"
        :key="tool.id"
        class="tool-card"
        @click="goToTool(tool.route)"
      >
        <div class="tool-image">
          <div class="tool-icon-emoji">{{ tool.icon }}</div>
        </div>
        <div class="tool-content">
          <h2 class="tool-title">{{ tool.title }}</h2>
          <p class="tool-description">{{ tool.description }}</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.tools-container {
  min-height: 100vh;
  background: #ffffff;
  background-image:
    radial-gradient(at 0% 0%, rgba(59, 130, 246, 0.03) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(139, 92, 246, 0.03) 0px, transparent 50%);
  padding: 2rem 1rem;
  position: relative;
  overflow-x: hidden;
}

.tools-header {
  text-align: center;
  margin-bottom: 2rem;
  padding: 2rem 0;
  position: relative;
  z-index: 1;
}

.tools-title {
  font-size: 3rem;
  font-weight: 800;
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 0.5rem;
  letter-spacing: -0.02em;
}

.tools-subtitle {
  font-size: 1rem;
  color: #6b7280;
  margin: 0;
  font-weight: 300;
}

.tools-grid {
  max-width: 1600px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 0.75rem;
  position: relative;
  z-index: 1;
}

@media (min-width: 640px) {
  .tools-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 0.75rem;
  }
}

@media (min-width: 768px) {
  .tools-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
  }
}

@media (min-width: 1024px) {
  .tools-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 1rem;
  }
}

@media (min-width: 1280px) {
  .tools-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 1.25rem;
  }
}

.tool-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  overflow: hidden;
  transition: all 0.3s ease;
  display: block;
  text-decoration: none;
  color: inherit;
  cursor: pointer;
}

.tool-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1);
  border-color: #d1d5db;
}

.tool-image {
  width: 100%;
  height: 80px;
  overflow: hidden;
  background: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.75rem;
}

.tool-icon-emoji {
  font-size: 2.5rem;
  line-height: 1;
}

.tool-content {
  padding: 0.75rem;
}

.tool-title {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 0.5rem;
  line-height: 1.3;
}

.tool-description {
  font-size: 0.75rem;
  line-height: 1.4;
  color: #6b7280;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

@media (max-width: 768px) {
  .tools-title {
    font-size: 2rem;
  }
  
  .tools-grid {
    grid-template-columns: 1fr;
  }
  
  .tool-card {
    padding: 1.25rem;
  }
  
  .tool-icon {
    font-size: 2.5rem;
  }
}
</style>

