<template>
  <div class="admin-books-container">
    <div class="admin-header">
      <h1 class="admin-title">Book管理</h1>
      <p class="admin-subtitle">管理系统书籍</p>
      <button @click="showCreateModal = true" class="btn-create">
        <span>+</span> 新建书籍
      </button>
    </div>

    <div v-if="loading" class="loading">
      <div class="spinner"></div>
      <p>加载中...</p>
    </div>

    <div v-else-if="error" class="error-message">
      {{ error }}
    </div>

    <div v-else class="admin-content">
      <div class="books-table-container">
        <table class="books-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>封面</th>
              <th>书名</th>
              <th>作者</th>
              <th>出版时间</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="book in books" :key="book.id">
              <td>{{ book.id }}</td>
              <td class="cover-cell">
                <img 
                  v-if="book.cover_image" 
                  :src="book.cover_image" 
                  :alt="book.title"
                  class="cover-thumbnail"
                  @error="handleImageError"
                />
                <span v-else class="no-cover-text">无封面</span>
              </td>
              <td class="title-cell">{{ book.title }}</td>
              <td>{{ book.author }}</td>
              <td>{{ formatDate(book.publish_date) }}</td>
              <td class="actions">
                <button @click="editBook(book)" class="btn btn-sm btn-edit">编辑</button>
                <button @click="deleteBook(book)" class="btn btn-sm btn-danger">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 创建/编辑书籍模态框 -->
    <div v-if="showCreateModal || editingBook" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>{{ editingBook ? '编辑书籍' : '新建书籍' }}</h3>
          <button @click="closeModal" class="btn-close">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>书名 *</label>
            <input v-model="bookForm.title" type="text" placeholder="请输入书名" required />
          </div>
          <div class="form-group">
            <label>作者 *</label>
            <input v-model="bookForm.author" type="text" placeholder="请输入作者" required />
          </div>
          <div class="form-group">
            <label>出版时间 *</label>
            <input v-model="bookForm.publish_date" type="date" required />
          </div>
          <div class="form-group">
            <label>封面图片URL</label>
            <input v-model="bookForm.cover_image" type="text" placeholder="请输入封面图片URL或本地路径（如：/book-covers/xxx.jpg）" />
            <small class="form-hint">支持URL或本地路径（如：/book-covers/xxx.jpg）</small>
            <div v-if="bookForm.cover_image" class="cover-preview">
              <img :src="bookForm.cover_image" alt="封面预览" @error="previewError = true" />
              <span v-if="previewError" class="preview-error">图片加载失败</span>
            </div>
          </div>
          <div class="form-group">
            <label>简介</label>
            <textarea v-model="bookForm.description" placeholder="请输入书籍简介" rows="5"></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="closeModal" class="btn-cancel">取消</button>
          <button @click="saveBook" class="btn-save" :disabled="!bookForm.title || !bookForm.author || !bookForm.publish_date">
            {{ editingBook ? '保存' : '创建' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAuth } from '../composables/useAuth'

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'
const { token } = useAuth()

const books = ref([])
const loading = ref(true)
const error = ref('')
const showCreateModal = ref(false)
const editingBook = ref(null)
const previewError = ref(false)

const bookForm = ref({
  title: '',
  author: '',
  publish_date: '',
  cover_image: '',
  description: ''
})

onMounted(() => {
  if (!token.value) {
    error.value = '请先登录'
    loading.value = false
    return
  }
  fetchBooks()
})

const fetchBooks = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const response = await fetch(`${API_BASE_URL}/api/books`, {
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('请先登录')
      }
      throw new Error('获取书籍列表失败')
    }

    const data = await response.json()
    books.value = data
  } catch (err) {
    error.value = err.message || '加载书籍列表失败'
  } finally {
    loading.value = false
  }
}

const editBook = (book) => {
  editingBook.value = book
  previewError.value = false
  bookForm.value = {
    title: book.title,
    author: book.author,
    publish_date: book.publish_date ? book.publish_date.split('T')[0] : '',
    cover_image: book.cover_image || '',
    description: book.description || ''
  }
}

const closeModal = () => {
  showCreateModal.value = false
  editingBook.value = null
  previewError.value = false
  bookForm.value = {
    title: '',
    author: '',
    publish_date: '',
    cover_image: '',
    description: ''
  }
}

const saveBook = async () => {
  if (!bookForm.value.title || !bookForm.value.author || !bookForm.value.publish_date) {
    return
  }

  try {
    const publishDate = new Date(bookForm.value.publish_date).toISOString()
    const payload = {
      title: bookForm.value.title,
      author: bookForm.value.author,
      publish_date: publishDate,
      cover_image: bookForm.value.cover_image || null,
      description: bookForm.value.description || null
    }

    let response
    if (editingBook.value) {
      response = await fetch(`${API_BASE_URL}/api/admin/books/${editingBook.value.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token.value}`,
        },
        body: JSON.stringify(payload),
      })
    } else {
      response = await fetch(`${API_BASE_URL}/api/admin/books`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token.value}`,
        },
        body: JSON.stringify(payload),
      })
    }

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      throw new Error(errorData.detail || (editingBook.value ? '更新失败' : '创建失败'))
    }

    await fetchBooks()
    closeModal()
  } catch (err) {
    alert(err.message || '操作失败')
  }
}

const deleteBook = async (book) => {
  if (!confirm(`确定要删除书籍"${book.title}"吗？`)) {
    return
  }

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/books/${book.id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      throw new Error('删除失败')
    }

    await fetchBooks()
  } catch (err) {
    alert(err.message || '删除失败')
  }
}

const formatDate = (dateString) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const handleImageError = (event) => {
  event.target.style.display = 'none'
}
</script>

<style scoped>
.admin-books-container {
  min-height: calc(100vh - 80px);
  padding: 2rem 1rem;
  background: #ffffff;
}

.admin-header {
  max-width: 1600px;
  margin: 0 auto 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.admin-title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 0.5rem;
}

.admin-subtitle {
  font-size: 1rem;
  color: #6b7280;
}

.btn-create {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  color: #ffffff;
  border: none;
  border-radius: 8px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-create:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.loading,
.error-message {
  text-align: center;
  padding: 3rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-message {
  color: #ef4444;
}

.admin-content {
  max-width: 1600px;
  margin: 0 auto;
}

.books-table-container {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.books-table {
  width: 100%;
  border-collapse: collapse;
}

.books-table thead {
  background: #f9fafb;
}

.books-table th {
  padding: 1rem;
  text-align: left;
  font-weight: 600;
  color: #374151;
  font-size: 0.875rem;
  border-bottom: 2px solid #e5e7eb;
}

.books-table td {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  color: #111827;
}

.books-table tbody tr:hover {
  background: #f9fafb;
}

.cover-cell {
  width: 80px;
}

.cover-thumbnail {
  width: 60px;
  height: 90px;
  object-fit: cover;
  border-radius: 4px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.no-cover-text {
  color: #9ca3af;
  font-size: 0.75rem;
}

.title-cell {
  max-width: 300px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.actions {
  display: flex;
  gap: 0.5rem;
}

.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-sm {
  padding: 0.375rem 0.75rem;
  font-size: 0.75rem;
}

.btn-edit {
  background: #3b82f6;
  color: #ffffff;
}

.btn-edit:hover {
  background: #2563eb;
}

.btn-danger {
  background: #ef4444;
  color: #ffffff;
}

.btn-danger:hover {
  background: #dc2626;
}

/* 模态框样式 */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 2rem;
  overflow-y: auto;
}

.modal-content {
  background: #ffffff;
  border-radius: 12px;
  width: 90%;
  max-width: 800px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.modal-header h3 {
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
  margin: 0;
}

.btn-close {
  background: transparent;
  border: none;
  font-size: 1.5rem;
  color: #6b7280;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: all 0.2s;
}

.btn-close:hover {
  background: #f3f4f6;
  color: #111827;
}

.modal-body {
  padding: 1.5rem;
}

.form-group {
  margin-bottom: 1.25rem;
}

.form-group label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 0.75rem;
  font-size: 1rem;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  transition: all 0.2s;
  box-sizing: border-box;
  font-family: inherit;
}

.form-group input:focus,
.form-group textarea:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.form-group textarea {
  resize: vertical;
}

.form-hint {
  display: block;
  margin-top: 0.25rem;
  font-size: 0.75rem;
  color: #6b7280;
}

.cover-preview {
  margin-top: 0.75rem;
  padding: 1rem;
  background: #f9fafb;
  border-radius: 8px;
  text-align: center;
}

.cover-preview img {
  max-width: 200px;
  max-height: 300px;
  border-radius: 4px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.preview-error {
  display: block;
  color: #ef4444;
  font-size: 0.875rem;
  margin-top: 0.5rem;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  padding: 1.5rem;
  border-top: 1px solid #e5e7eb;
}

.btn-cancel,
.btn-save {
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  font-weight: 500;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel {
  background: #f9fafb;
  color: #374151;
}

.btn-cancel:hover {
  background: #f3f4f6;
}

.btn-save {
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  color: #ffffff;
}

.btn-save:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.btn-save:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

@media (max-width: 768px) {
  .books-table-container {
    overflow-x: auto;
  }

  .books-table {
    min-width: 800px;
  }
}
</style>

