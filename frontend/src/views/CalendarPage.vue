<script setup>
import Calendar from '../components/Calendar.vue'
</script>

<template>
  <div class="calendar-page">
    <div class="page-container">
      <Calendar />
    </div>
  </div>
</template>

<style scoped>
.calendar-page {
  min-height: 100vh;
  background: #ffffff;
  padding: 2rem 1rem;
  display: flex;
  justify-content: center;
  align-items: flex-start;
}

.page-container {
  max-width: 900px;
  width: 100%;
}
</style>

