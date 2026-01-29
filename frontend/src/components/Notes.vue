<template>
  <div class="notes-wrapper">
    <div class="notes-container">
      <!-- 工具栏 -->
      <div class="notes-toolbar">
        <button class="toolbar-btn" @click="addNote" title="新建便签">
          ➕ 新建
        </button>
        <button class="toolbar-btn" @click="deleteSelected" :disabled="selectedNotes.length === 0" title="删除选中">
          🗑️ 删除
        </button>
        <div class="search-box">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="搜索便签..."
            class="search-input"
          />
        </div>
      </div>

      <!-- 便签列表 -->
      <div class="notes-grid">
        <div
          v-for="note in filteredNotes"
          :key="note.id"
          class="note-card"
          :class="{ selected: selectedNotes.includes(note.id) }"
          @click="toggleSelect(note.id)"
          @dblclick="editNote(note)"
        >
          <div class="note-header">
            <input
              v-if="editingNoteId === note.id"
              v-model="editingTitle"
              @blur="saveNote"
              @keyup.enter="saveNote"
              class="note-title-input"
              @click.stop
            />
            <h3 v-else class="note-title">{{ note.title || '无标题' }}</h3>
            <div class="note-actions" @click.stop>
              <button class="action-btn" @click.stop="editNote(note)" title="编辑">✏️</button>
              <button class="action-btn" @click.stop="deleteNote(note.id)" title="删除">🗑️</button>
            </div>
          </div>
          <div class="note-content-wrapper">
            <textarea
              v-if="editingNoteId === note.id"
              v-model="editingContent"
              @blur="saveNote"
              class="note-content-input"
              @click.stop
              placeholder="输入内容..."
            ></textarea>
            <div v-else class="note-content" v-html="formatContent(note.content)"></div>
          </div>
          <div class="note-footer">
            <span class="note-date">{{ formatDate(note.updatedAt) }}</span>
            <span class="note-word-count">{{ note.content.length }} 字</span>
          </div>
        </div>
      </div>

      <!-- 空状态 -->
      <div v-if="filteredNotes.length === 0" class="empty-notes">
        <div class="empty-icon">📝</div>
        <p class="empty-text">{{ searchQuery ? '没有找到匹配的便签' : '还没有便签，点击"新建"创建第一个便签吧' }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const notes = ref([])
const selectedNotes = ref([])
const editingNoteId = ref(null)
const editingTitle = ref('')
const editingContent = ref('')
const searchQuery = ref('')

// 从 localStorage 加载便签
const loadNotes = () => {
  const saved = localStorage.getItem('notes')
  if (saved) {
    notes.value = JSON.parse(saved)
  } else {
    // 初始化示例便签
    notes.value = [
      {
        id: Date.now(),
        title: '欢迎使用便签',
        content: '这是一个简洁美观的便签工具，支持创建、编辑、删除和搜索功能。\n\n双击便签可以快速编辑。',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      }
    ]
    saveNotes()
  }
}

// 保存便签到 localStorage
const saveNotes = () => {
  localStorage.setItem('notes', JSON.stringify(notes.value))
}

// 添加新便签
const addNote = () => {
  const newNote = {
    id: Date.now(),
    title: '',
    content: '',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
  notes.value.unshift(newNote)
  saveNotes()
  editingNoteId.value = newNote.id
  editingTitle.value = ''
  editingContent.value = ''
  setTimeout(() => {
    const titleInput = document.querySelector('.note-title-input')
    if (titleInput) titleInput.focus()
  }, 100)
}

// 编辑便签
const editNote = (note) => {
  editingNoteId.value = note.id
  editingTitle.value = note.title
  editingContent.value = note.content
  selectedNotes.value = []
}

// 保存便签
const saveNote = () => {
  if (!editingNoteId.value) return
  
  const note = notes.value.find(n => n.id === editingNoteId.value)
  if (note) {
    note.title = editingTitle.value.trim()
    note.content = editingContent.value.trim()
    note.updatedAt = new Date().toISOString()
    saveNotes()
  }
  editingNoteId.value = null
}

// 删除便签
const deleteNote = (id) => {
  notes.value = notes.value.filter(n => n.id !== id)
  selectedNotes.value = selectedNotes.value.filter(n => n !== id)
  saveNotes()
}

// 删除选中的便签
const deleteSelected = () => {
  notes.value = notes.value.filter(n => !selectedNotes.value.includes(n.id))
  selectedNotes.value = []
  saveNotes()
}

// 切换选中状态
const toggleSelect = (id) => {
  if (editingNoteId.value) return // 编辑时不允许选择
  
  const index = selectedNotes.value.indexOf(id)
  if (index > -1) {
    selectedNotes.value.splice(index, 1)
  } else {
    selectedNotes.value.push(id)
  }
}

// 格式化内容（简单的换行处理）
const formatContent = (content) => {
  if (!content) return ''
  return content.replace(/\n/g, '<br>')
}

// 格式化日期
const formatDate = (dateString) => {
  const date = new Date(dateString)
  const now = new Date()
  const diff = now - date
  const days = Math.floor(diff / (1000 * 60 * 60 * 24))
  
  if (days === 0) {
    const hours = Math.floor(diff / (1000 * 60 * 60))
    if (hours === 0) {
      const minutes = Math.floor(diff / (1000 * 60))
      return minutes <= 1 ? '刚刚' : `${minutes}分钟前`
    }
    return `${hours}小时前`
  } else if (days === 1) {
    return '昨天'
  } else if (days < 7) {
    return `${days}天前`
  } else {
    return date.toLocaleDateString('zh-CN', { month: 'short', day: 'numeric' })
  }
}

// 过滤便签
const filteredNotes = computed(() => {
  if (!searchQuery.value.trim()) {
    return notes.value
  }
  const query = searchQuery.value.toLowerCase()
  return notes.value.filter(note => 
    note.title.toLowerCase().includes(query) || 
    note.content.toLowerCase().includes(query)
  )
})

onMounted(() => {
  loadNotes()
})
</script>

<style scoped>
.notes-wrapper {
  display: flex;
  justify-content: center;
  padding: 2rem 0;
}

.notes-container {
  max-width: 1400px;
  width: 100%;
}

.notes-toolbar {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
  align-items: center;
  flex-wrap: wrap;
}

.toolbar-btn {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  color: #ffffff;
  padding: 0.6rem 1.5rem;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.toolbar-btn:hover:not(:disabled) {
  background: rgba(0, 212, 255, 0.2);
  border-color: #00d4ff;
  transform: translateY(-2px);
}

.toolbar-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.search-box {
  flex: 1;
  min-width: 200px;
}

.search-input {
  width: 100%;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  color: #ffffff;
  padding: 0.6rem 1rem;
  font-size: 0.9rem;
  transition: all 0.3s ease;
}

.search-input:focus {
  outline: none;
  border-color: #00d4ff;
  background: rgba(255, 255, 255, 0.15);
}

.search-input::placeholder {
  color: rgba(255, 255, 255, 0.5);
}

.notes-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
}

.note-card {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  display: flex;
  flex-direction: column;
  min-height: 200px;
  position: relative;
}

.note-card:hover {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(255, 255, 255, 0.2);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.note-card.selected {
  border-color: #00d4ff;
  background: rgba(0, 212, 255, 0.1);
  box-shadow: 0 0 20px rgba(0, 212, 255, 0.3);
}

.note-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
  gap: 1rem;
}

.note-title {
  font-size: 1.1rem;
  font-weight: 600;
  color: #ffffff;
  margin: 0;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.note-title-input {
  flex: 1;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  color: #ffffff;
  padding: 0.5rem;
  font-size: 1.1rem;
  font-weight: 600;
  font-family: inherit;
}

.note-title-input:focus {
  outline: none;
  border-color: #00d4ff;
  background: rgba(255, 255, 255, 0.15);
}

.note-actions {
  display: flex;
  gap: 0.5rem;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.note-card:hover .note-actions {
  opacity: 1;
}

.action-btn {
  background: transparent;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  cursor: pointer;
  font-size: 1rem;
  padding: 0.3rem;
  border-radius: 4px;
  transition: all 0.3s ease;
}

.action-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #ffffff;
}

.note-content-wrapper {
  flex: 1;
  margin-bottom: 1rem;
}

.note-content {
  color: rgba(255, 255, 255, 0.8);
  line-height: 1.6;
  font-size: 0.95rem;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 8;
  -webkit-box-orient: vertical;
  word-break: break-word;
}

.note-content-input {
  width: 100%;
  min-height: 120px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  color: #ffffff;
  padding: 0.75rem;
  font-size: 0.95rem;
  font-family: inherit;
  line-height: 1.6;
  resize: vertical;
}

.note-content-input:focus {
  outline: none;
  border-color: #00d4ff;
  background: rgba(255, 255, 255, 0.15);
}

.note-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.5);
  padding-top: 1rem;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.empty-notes {
  text-align: center;
  padding: 4rem 2rem;
  color: rgba(255, 255, 255, 0.5);
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.empty-text {
  font-size: 1.1rem;
  margin: 0;
}

@media (max-width: 768px) {
  .notes-grid {
    grid-template-columns: 1fr;
  }
  
  .notes-toolbar {
    flex-direction: column;
    align-items: stretch;
  }
  
  .search-box {
    min-width: 100%;
  }
}
</style>

