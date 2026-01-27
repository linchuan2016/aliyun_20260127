<script setup>
import { ref, onMounted } from 'vue'

const msg = ref('等待数据中...')

// 页面加载时向后端请求数据
onMounted(async () => {
  try {
    // 生产环境：使用相对路径（通过 Nginx 代理）
    // 本地开发：使用环境变量或默认本地地址
    const apiUrl = import.meta.env.VITE_API_URL || '';
    // 如果 apiUrl 为空，使用相对路径（生产环境）
    // 如果 apiUrl 有值，使用完整 URL（本地开发）
    const url = apiUrl ? `${apiUrl}/api/data` : '/api/data';
    const response = await fetch(url);
    
    const data = await response.json()
    msg.value = data.message
  } catch (error) {
    msg.value = "无法连接到后端！"
    console.error(error)
  }
})
</script>

<template>
  <div style="text-align: center; margin-top: 50px;">
    <h1>Lin</h1>
    <p style="font-size: 24px; color: #42b983;">
      {{ msg }}
    </p>
  </div>
</template>




