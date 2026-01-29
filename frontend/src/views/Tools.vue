<script setup>
import { ref } from 'vue'
import Calendar from '../components/Calendar.vue'
import Notes from '../components/Notes.vue'

const activeTool = ref('calendar') // 'calendar' or 'notes'

const switchTool = (tool) => {
  activeTool.value = tool
}
</script>

<template>
  <div class="tools-container">
    <header class="tools-header">
      <h1 class="tools-title">实用工具</h1>
      <p class="tools-subtitle">便捷的在线工具集合</p>
    </header>

    <div class="tools-tabs">
      <button 
        class="tool-tab" 
        :class="{ active: activeTool === 'calendar' }"
        @click="switchTool('calendar')"
      >
        📅 万年历
      </button>
      <button 
        class="tool-tab" 
        :class="{ active: activeTool === 'notes' }"
        @click="switchTool('notes')"
      >
        📝 便签
      </button>
    </div>

    <div class="tools-content">
      <Calendar v-if="activeTool === 'calendar'" />
      <Notes v-if="activeTool === 'notes'" />
    </div>
  </div>
</template>

<style scoped>
.tools-container {
  min-height: 100vh;
  background: #0a0a0a;
  background-image:
    radial-gradient(at 0% 0%, rgba(0, 212, 255, 0.1) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(138, 43, 226, 0.1) 0px, transparent 50%);
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
  background: linear-gradient(135deg, #00d4ff 0%, #8a2be2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 0.5rem;
  letter-spacing: -0.02em;
}

.tools-subtitle {
  font-size: 1rem;
  color: rgba(255, 255, 255, 0.6);
  margin: 0;
  font-weight: 300;
}

.tools-tabs {
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.tool-tab {
  padding: 0.75rem 2rem;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.tool-tab:hover {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 255, 255, 0.2);
  color: #ffffff;
  transform: translateY(-2px);
}

.tool-tab.active {
  background: rgba(0, 212, 255, 0.1);
  border-color: #00d4ff;
  color: #00d4ff;
  box-shadow: 0 4px 12px rgba(0, 212, 255, 0.2);
}

.tools-content {
  max-width: 1400px;
  margin: 0 auto;
  position: relative;
  z-index: 1;
}

@media (max-width: 768px) {
  .tools-title {
    font-size: 2rem;
  }
  
  .tool-tab {
    padding: 0.6rem 1.5rem;
    font-size: 0.9rem;
  }
}
</style>

