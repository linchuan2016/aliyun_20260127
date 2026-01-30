<script setup>
import Navigation from './components/Navigation.vue'
</script>

<template>
  <div class="app-wrapper">
    <Navigation />
    <router-view />
  </div>
</template>

<style>
.app-wrapper {
  min-height: 100vh;
  background: #ffffff;
}
</style>
