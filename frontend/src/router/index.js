import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Tools from '../views/Tools.vue'
import CalendarPage from '../views/CalendarPage.vue'
import NotesPage from '../views/NotesPage.vue'
import RAG from '../views/RAG.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/tools',
    name: 'Tools',
    component: Tools
  },
  {
    path: '/tools/calendar',
    name: 'CalendarPage',
    component: CalendarPage
  },
  {
    path: '/tools/notes',
    name: 'NotesPage',
    component: NotesPage
  },
  {
    path: '/rag',
    name: 'RAG',
    component: RAG
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router

