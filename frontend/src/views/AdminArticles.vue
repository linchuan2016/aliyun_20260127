<template>
  <div class="admin-articles-container">
    <div class="admin-header">
      <h1 class="admin-title">文章管理</h1>
      <p class="admin-subtitle">管理系统文章</p>
      <button @click="showCreateModal = true" class="btn-create">
        <span>+</span> 新建文章
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
      <div class="articles-table-container">
        <table class="articles-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>标题</th>
              <th>发布时间</th>
              <th>作者</th>
              <th>分类</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="article in articles" :key="article.id">
              <td>{{ article.id }}</td>
              <td class="title-cell">{{ article.title }}</td>
              <td>{{ formatDate(article.publish_date) }}</td>
              <td>{{ article.author }}</td>
              <td>
                <span v-if="article.category" class="category-tag">{{ article.category }}</span>
                <span v-else>-</span>
              </td>
              <td class="actions">
                <button @click="editArticle(article)" class="btn btn-sm btn-edit">编辑</button>
                <button @click="deleteArticle(article)" class="btn btn-sm btn-danger">删除</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- 创建/编辑文章模态框 -->
    <div v-if="showCreateModal || editingArticle" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>{{ editingArticle ? '编辑文章' : '新建文章' }}</h3>
          <button @click="closeModal" class="btn-close">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group">
            <label>标题 *</label>
            <input v-model="articleForm.title" type="text" placeholder="请输入标题" required />
          </div>
          <div class="form-group">
            <label>发布时间 *</label>
            <input v-model="articleForm.publish_date" type="date" required />
          </div>
          <div class="form-group">
            <label>作者 *</label>
            <input v-model="articleForm.author" type="text" placeholder="请输入作者" required />
          </div>
          <div class="form-group">
            <label>原文地址</label>
            <input v-model="articleForm.original_url" type="url" placeholder="https://..." />
          </div>
          <div class="form-group">
            <label>分类</label>
            <input v-model="articleForm.category" type="text" placeholder="例如：科技" />
          </div>
          <div class="form-group">
            <label>摘要</label>
            <textarea v-model="articleForm.excerpt" placeholder="请输入摘要" rows="3"></textarea>
          </div>
          <div class="form-group">
            <label>内容</label>
            <textarea v-model="articleForm.content" placeholder="请输入文章内容（支持HTML）" rows="10"></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="closeModal" class="btn-cancel">取消</button>
          <button @click="saveArticle" class="btn-save" :disabled="!articleForm.title || !articleForm.publish_date || !articleForm.author">
            {{ editingArticle ? '保存' : '创建' }}
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

const articles = ref([])
const loading = ref(true)
const error = ref('')
const showCreateModal = ref(false)
const editingArticle = ref(null)

const articleForm = ref({
  title: '',
  publish_date: '',
  author: '',
  original_url: '',
  category: '',
  excerpt: '',
  content: ''
})

onMounted(() => {
  if (!token.value) {
    error.value = '请先登录'
    loading.value = false
    return
  }
  fetchArticles()
})

const fetchArticles = async () => {
  loading.value = true
  error.value = ''
  
  try {
    const response = await fetch(`${API_BASE_URL}/api/articles`, {
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('请先登录')
      }
      throw new Error('获取文章列表失败')
    }

    const data = await response.json()
    articles.value = data
  } catch (err) {
    error.value = err.message || '加载文章列表失败'
  } finally {
    loading.value = false
  }
}

const editArticle = (article) => {
  editingArticle.value = article
  articleForm.value = {
    title: article.title,
    publish_date: article.publish_date ? article.publish_date.split('T')[0] : '',
    author: article.author,
    original_url: article.original_url || '',
    category: article.category || '',
    excerpt: article.excerpt || '',
    content: article.content || ''
  }
}

const closeModal = () => {
  showCreateModal.value = false
  editingArticle.value = null
  articleForm.value = {
    title: '',
    publish_date: '',
    author: '',
    original_url: '',
    category: '',
    excerpt: '',
    content: ''
  }
}

const saveArticle = async () => {
  if (!articleForm.value.title || !articleForm.value.publish_date || !articleForm.value.author) {
    return
  }

  try {
    const publishDate = new Date(articleForm.value.publish_date).toISOString()
    const payload = {
      ...articleForm.value,
      publish_date: publishDate
    }

    let response
    if (editingArticle.value) {
      response = await fetch(`${API_BASE_URL}/api/admin/articles/${editingArticle.value.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token.value}`,
        },
        body: JSON.stringify(payload),
      })
    } else {
      response = await fetch(`${API_BASE_URL}/api/admin/articles`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token.value}`,
        },
        body: JSON.stringify(payload),
      })
    }

    if (!response.ok) {
      throw new Error(editingArticle.value ? '更新失败' : '创建失败')
    }

    await fetchArticles()
    closeModal()
  } catch (err) {
    alert(err.message || '操作失败')
  }
}

const deleteArticle = async (article) => {
  if (!confirm(`确定要删除文章"${article.title}"吗？`)) {
    return
  }

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/articles/${article.id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      throw new Error('删除失败')
    }

    await fetchArticles()
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
</script>

<style scoped>
.admin-articles-container {
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

.articles-table-container {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.articles-table {
  width: 100%;
  border-collapse: collapse;
}

.articles-table thead {
  background: #f9fafb;
}

.articles-table th {
  padding: 1rem;
  text-align: left;
  font-weight: 600;
  color: #374151;
  font-size: 0.875rem;
  border-bottom: 2px solid #e5e7eb;
}

.articles-table td {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  color: #111827;
}

.articles-table tbody tr:hover {
  background: #f9fafb;
}

.title-cell {
  max-width: 400px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.category-tag {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  background: rgba(59, 130, 246, 0.1);
  color: #3b82f6;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 500;
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
  .articles-table-container {
    overflow-x: auto;
  }

  .articles-table {
    min-width: 800px;
  }
}
</style>

