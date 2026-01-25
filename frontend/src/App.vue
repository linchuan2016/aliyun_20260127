<script setup>
import { ref, onMounted } from 'vue'

const msg = ref('等待数据中...')

// 页面加载时向后端请求数据
onMounted(async () => {
  try {
    const response = await fetch('http://127.0.0.1:8000/api/data')
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




