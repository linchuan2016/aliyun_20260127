<script setup>
import Notes from '../components/Notes.vue'
</script>

<template>
  <div class="notes-page">
    <div class="page-container">
      <Notes />
    </div>
  </div>
</template>

<style scoped>
.notes-page {
  min-height: 100vh;
  background: #ffffff;
  padding: 2rem 1rem;
  display: flex;
  justify-content: center;
  align-items: flex-start;
}

.page-container {
  max-width: 1200px;
  width: 100%;
}
</style>

