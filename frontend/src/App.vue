<script setup>
import { ref, onMounted } from 'vue'

const msg = ref('等待数据中...')

// 页面加载时向后端请求数据
onMounted(async () => {
  try {
    // 生产环境：使用服务器 IP 地址
    // 本地开发：使用相对路径（通过 Vite 代理）
    const isProduction = window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1';
    const apiUrl = isProduction ? 'http://47.112.29.212' : '';
    const url = `${apiUrl}/api/data`;
    
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




