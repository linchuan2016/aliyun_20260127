<template>
  <div class="admin-container">
    <div class="admin-header">
      <h1 class="admin-title">后台管理</h1>
      <div class="admin-tabs">
        <button 
          @click="activeTab = 'users'" 
          :class="['admin-tab', { active: activeTab === 'users' }]"
        >
          用户管理
        </button>
        <button 
          @click="activeTab = 'articles'" 
          :class="['admin-tab', { active: activeTab === 'articles' }]"
        >
          文章管理
        </button>
        <button 
          @click="activeTab = 'books'" 
          :class="['admin-tab', { active: activeTab === 'books' }]"
        >
          Book管理
        </button>
      </div>
    </div>

    <!-- 用户管理 -->
    <div v-if="activeTab === 'users'">
      <div v-if="usersLoading" class="loading">
        <div class="spinner"></div>
        <p>加载中...</p>
      </div>

      <div v-else-if="usersError" class="error-message">
        {{ usersError }}
      </div>

      <div v-else class="admin-content">
        <div class="stats-bar">
          <div class="stat-card">
            <div class="stat-value">{{ total }}</div>
            <div class="stat-label">总用户数</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ activeCount }}</div>
            <div class="stat-label">活跃用户</div>
          </div>
          <div class="stat-card">
            <div class="stat-value">{{ inactiveCount }}</div>
            <div class="stat-label">禁用用户</div>
          </div>
        </div>

        <div class="users-table-container">
          <table class="users-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>用户名</th>
                <th>邮箱</th>
                <th>状态</th>
                <th>注册时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="user in users" :key="user.id" :class="{ 'inactive': !user.is_active }">
                <td>{{ user.id }}</td>
                <td>{{ user.username }}</td>
                <td>{{ user.email }}</td>
                <td>
                  <span :class="['status-badge', user.is_active ? 'active' : 'inactive']">
                    {{ user.is_active ? '活跃' : '禁用' }}
                  </span>
                </td>
                <td>{{ formatDate(user.created_at) }}</td>
                <td class="actions">
                  <button
                    @click="toggleUserStatus(user)"
                    :class="['btn', 'btn-sm', user.is_active ? 'btn-warning' : 'btn-success']"
                    :disabled="user.id === currentUser?.id"
                  >
                    {{ user.is_active ? '禁用' : '启用' }}
                  </button>
                  <button
                    @click="deleteUser(user)"
                    class="btn btn-sm btn-danger"
                    :disabled="user.id === currentUser?.id"
                  >
                    删除
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 文章管理 -->
    <div v-if="activeTab === 'articles'">
      <div class="admin-content-header">
        <button @click="showArticleModal = true" class="btn-create">
          <span>+</span> 新建文章
        </button>
      </div>

      <div v-if="articlesLoading" class="loading">
        <div class="spinner"></div>
        <p>加载中...</p>
      </div>

      <div v-else-if="articlesError" class="error-message">
        {{ articlesError }}
      </div>

      <div v-else class="admin-content">
        <div class="articles-table-container">
          <table class="articles-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>封面</th>
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
                <td class="cover-cell">
                  <img 
                    v-if="article.cover_image" 
                    :src="article.cover_image" 
                    :alt="article.title"
                    class="cover-thumbnail"
                    @error="handleImageError"
                  />
                  <span v-else class="no-cover-text">无封面</span>
                </td>
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
      <div v-if="showArticleModal || editingArticle" class="modal-overlay" @click="closeArticleModal">
        <div class="modal-content" @click.stop>
          <div class="modal-header">
            <h3>{{ editingArticle ? '编辑文章' : '新建文章' }}</h3>
            <button @click="closeArticleModal" class="btn-close">×</button>
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
              <label>封面图片URL</label>
              <input v-model="articleForm.cover_image" type="text" placeholder="请输入封面图片URL或本地路径（如：/article-covers/xxx.jpg）" />
              <small class="form-hint">支持URL或本地路径（如：/article-covers/xxx.jpg）</small>
              <div v-if="articleForm.cover_image" class="cover-preview">
                <img :src="articleForm.cover_image" alt="封面预览" @error="articlePreviewError = true" @load="articlePreviewError = false" />
                <span v-if="articlePreviewError" class="preview-error">图片加载失败</span>
              </div>
            </div>
            <div class="form-group">
              <label>摘要</label>
              <textarea v-model="articleForm.excerpt" placeholder="请输入摘要" rows="3"></textarea>
            </div>
            <div class="form-group">
              <label>内容（中文）</label>
              <textarea v-model="articleForm.content" placeholder="请输入文章内容（支持HTML）" rows="10"></textarea>
            </div>
            <div class="form-group">
              <label>内容（英文）</label>
              <textarea v-model="articleForm.content_en" placeholder="请输入文章英文内容" rows="10"></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button @click="closeArticleModal" class="btn-cancel">取消</button>
            <button @click="saveArticle" class="btn-save" :disabled="!articleForm.title || !articleForm.publish_date || !articleForm.author">
              {{ editingArticle ? '保存' : '创建' }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Book管理 -->
    <div v-if="activeTab === 'books'">
      <div class="admin-content-header">
        <button @click="showBookModal = true" class="btn-create">
          <span>+</span> 新建书籍
        </button>
      </div>

      <div v-if="booksLoading" class="loading">
        <div class="spinner"></div>
        <p>加载中...</p>
      </div>

      <div v-else-if="booksError" class="error-message">
        {{ booksError }}
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
                    @error="handleBookImageError"
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
      <div v-if="showBookModal || editingBook" class="modal-overlay" @click="closeBookModal">
        <div class="modal-content" @click.stop>
          <div class="modal-header">
            <h3>{{ editingBook ? '编辑书籍' : '新建书籍' }}</h3>
            <button @click="closeBookModal" class="btn-close">×</button>
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
                <img :src="bookForm.cover_image" alt="封面预览" @error="bookPreviewError = true" />
                <span v-if="bookPreviewError" class="preview-error">图片加载失败</span>
              </div>
            </div>
            <div class="form-group">
              <label>简介</label>
              <textarea v-model="bookForm.description" placeholder="请输入书籍简介" rows="5"></textarea>
            </div>
          </div>
          <div class="modal-footer">
            <button @click="closeBookModal" class="btn-cancel">取消</button>
            <button @click="saveBook" class="btn-save" :disabled="!bookForm.title || !bookForm.author || !bookForm.publish_date">
              {{ editingBook ? '保存' : '创建' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useAuth } from '../composables/useAuth'

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'
const { user: currentUser, token } = useAuth()
const route = useRoute()

// Tab管理
const activeTab = ref('users')

// 根据路由设置默认Tab
watch(() => route.path, (path) => {
  if (path === '/admin/articles') {
    activeTab.value = 'articles'
  } else if (path === '/admin/books') {
    activeTab.value = 'books'
  } else {
    activeTab.value = 'users'
  }
}, { immediate: true })

// 用户管理
const users = ref([])
const total = ref(0)
const usersLoading = ref(true)
const usersError = ref('')

const activeCount = computed(() => {
  return users.value.filter(u => u.is_active).length
})

const inactiveCount = computed(() => {
  return users.value.filter(u => !u.is_active).length
})

const fetchUsers = async () => {
  usersLoading.value = true
  usersError.value = ''
  
  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/users`, {
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      if (response.status === 401) {
        throw new Error('请先登录')
      }
      throw new Error('获取用户列表失败')
    }

    const data = await response.json()
    users.value = data.users
    total.value = data.total
  } catch (err) {
    usersError.value = err.message || '加载用户列表失败'
  } finally {
    usersLoading.value = false
  }
}

const toggleUserStatus = async (user) => {
  if (user.id === currentUser.value?.id) {
    alert('不能修改自己的状态')
    return
  }

  if (!confirm(`确定要${user.is_active ? '禁用' : '启用'}用户 "${user.username}" 吗？`)) {
    return
  }

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/users/${user.id}/status?is_active=${!user.is_active}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      throw new Error('更新用户状态失败')
    }

    await fetchUsers()
  } catch (err) {
    alert(err.message || '操作失败')
  }
}

const deleteUser = async (user) => {
  if (user.id === currentUser.value?.id) {
    alert('不能删除自己的账号')
    return
  }

  if (!confirm(`确定要删除用户 "${user.username}" 吗？此操作不可恢复！`)) {
    return
  }

  try {
    const response = await fetch(`${API_BASE_URL}/api/admin/users/${user.id}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${token.value}`,
      },
    })

    if (!response.ok) {
      throw new Error('删除用户失败')
    }

    await fetchUsers()
  } catch (err) {
    alert(err.message || '删除失败')
  }
}

// 文章管理
const articles = ref([])
const articlesLoading = ref(false)
const articlesError = ref('')
const showArticleModal = ref(false)
const editingArticle = ref(null)
const articlePreviewError = ref(false)

const articleForm = ref({
  title: '',
  publish_date: '',
  author: '',
  original_url: '',
  category: '',
  cover_image: '',
  excerpt: '',
  content: '',
  content_en: ''
})

const fetchArticles = async () => {
  articlesLoading.value = true
  articlesError.value = ''
  
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
    articlesError.value = err.message || '加载文章列表失败'
  } finally {
    articlesLoading.value = false
  }
}

const editArticle = (article) => {
  editingArticle.value = article
  articlePreviewError.value = false
  articleForm.value = {
    title: article.title,
    publish_date: article.publish_date ? article.publish_date.split('T')[0] : '',
    author: article.author,
    original_url: article.original_url || '',
    category: article.category || '',
    cover_image: article.cover_image || '',
    excerpt: article.excerpt || '',
    content: article.content || '',
    content_en: article.content_en || ''
  }
}

const closeArticleModal = () => {
  showArticleModal.value = false
  editingArticle.value = null
  articlePreviewError.value = false
  articleForm.value = {
    title: '',
    publish_date: '',
    author: '',
    original_url: '',
    category: '',
    cover_image: '',
    excerpt: '',
    content: '',
    content_en: ''
  }
}

const saveArticle = async () => {
  if (!articleForm.value.title || !articleForm.value.publish_date || !articleForm.value.author) {
    return
  }

  try {
    const publishDate = new Date(articleForm.value.publish_date).toISOString()
    // 构建payload，确保所有字段都被包含
    // 注意：cover_image 如果是空字符串，需要明确发送，不能转换为null
    // 因为null在Pydantic中表示"不更新此字段"
    const payload = {
      title: articleForm.value.title,
      publish_date: publishDate,
      author: articleForm.value.author,
      original_url: articleForm.value.original_url || null,
      category: articleForm.value.category || null,
      cover_image: articleForm.value.cover_image || null, // 空字符串转换为null（清空封面）
      excerpt: articleForm.value.excerpt || null,
      content: articleForm.value.content || null,
      content_en: articleForm.value.content_en || null
    }
    
    // 调试：打印要发送的cover_image值
    console.log('保存文章 - cover_image值:', payload.cover_image)

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
      const errorText = await response.text()
      console.error('保存文章失败:', errorText)
      throw new Error(editingArticle.value ? '更新失败' : '创建失败')
    }

    // 保存成功后刷新列表
    await fetchArticles()
    
    // 如果是在编辑模式，确保编辑的文章数据也被更新
    if (editingArticle.value) {
      const updatedArticle = articles.value.find(a => a.id === editingArticle.value.id)
      if (updatedArticle) {
        editingArticle.value = updatedArticle
      }
    }
    
    closeArticleModal()
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

// Book管理
const books = ref([])
const booksLoading = ref(false)
const booksError = ref('')
const showBookModal = ref(false)
const editingBook = ref(null)
const bookPreviewError = ref(false)

const bookForm = ref({
  title: '',
  author: '',
  publish_date: '',
  cover_image: '',
  description: ''
})

const fetchBooks = async () => {
  booksLoading.value = true
  booksError.value = ''
  
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
    booksError.value = err.message || '加载书籍列表失败'
  } finally {
    booksLoading.value = false
  }
}

const editBook = (book) => {
  editingBook.value = book
  bookPreviewError.value = false
  bookForm.value = {
    title: book.title,
    author: book.author,
    publish_date: book.publish_date ? book.publish_date.split('T')[0] : '',
    cover_image: book.cover_image || '',
    description: book.description || ''
  }
}

const closeBookModal = () => {
  showBookModal.value = false
  editingBook.value = null
  bookPreviewError.value = false
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
    closeBookModal()
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

const handleBookImageError = (event) => {
  event.target.style.display = 'none'
}

// 监听Tab切换，加载对应数据
watch(activeTab, (tab) => {
  if (tab === 'users' && users.value.length === 0) {
    fetchUsers()
  } else if (tab === 'articles' && articles.value.length === 0) {
    fetchArticles()
  } else if (tab === 'books' && books.value.length === 0) {
    fetchBooks()
  }
})

onMounted(() => {
  if (!token.value) {
    usersError.value = '请先登录'
    usersLoading.value = false
    return
  }
  // 根据当前Tab加载数据
  if (activeTab.value === 'users') {
    fetchUsers()
  } else if (activeTab.value === 'articles') {
    fetchArticles()
  } else if (activeTab.value === 'books') {
    fetchBooks()
  }
})
</script>

<style scoped>
.admin-container {
  min-height: calc(100vh - 80px);
  padding: 2rem 1rem;
  background: #ffffff;
  background-image:
    radial-gradient(at 0% 0%, rgba(59, 130, 246, 0.03) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(139, 92, 246, 0.03) 0px, transparent 50%);
}

.admin-header {
  max-width: 1600px;
  margin: 0 auto 2rem;
}

.admin-title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 0.5rem;
}

.admin-tabs {
  display: flex;
  gap: 1rem;
  margin-top: 1rem;
  border-bottom: 2px solid #e5e7eb;
}

.admin-tab {
  padding: 0.75rem 1.5rem;
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  margin-bottom: -2px;
  color: #6b7280;
  font-weight: 500;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s;
}

.admin-tab:hover {
  color: #111827;
}

.admin-tab.active {
  color: #3b82f6;
  border-bottom-color: #3b82f6;
}

.admin-content-header {
  max-width: 1600px;
  margin: 0 auto 1rem;
  display: flex;
  justify-content: flex-end;
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

.loading {
  text-align: center;
  padding: 3rem;
}

.spinner {
  border: 3px solid rgba(0, 0, 0, 0.1);
  border-top-color: #3b82f6;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-message {
  max-width: 1600px;
  margin: 0 auto;
  padding: 1rem;
  background: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 8px;
  color: #dc2626;
  text-align: center;
}

.admin-content {
  max-width: 1600px;
  margin: 0 auto;
}

.stats-bar {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-bottom: 2rem;
}

.stat-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 1.5rem;
  text-align: center;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  color: #3b82f6;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 0.875rem;
  color: #6b7280;
}

/* 表格样式 */
.users-table-container,
.articles-table-container,
.books-table-container {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.users-table,
.articles-table,
.books-table {
  width: 100%;
  border-collapse: collapse;
}

.users-table thead,
.articles-table thead,
.books-table thead {
  background: #f9fafb;
}

.users-table th,
.articles-table th,
.books-table th {
  padding: 1rem;
  text-align: left;
  font-weight: 600;
  color: #374151;
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 2px solid #e5e7eb;
}

.users-table td,
.articles-table td,
.books-table td {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  color: #111827;
}

.users-table tbody tr:hover,
.articles-table tbody tr:hover,
.books-table tbody tr:hover {
  background: #f9fafb;
}

.users-table tbody tr.inactive {
  opacity: 0.6;
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

.status-badge {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
}

.status-badge.active {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.inactive {
  background: #fee2e2;
  color: #991b1b;
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

.btn-success {
  background: #10b981;
  color: #ffffff;
}

.btn-success:hover:not(:disabled) {
  background: #059669;
}

.btn-warning {
  background: #f59e0b;
  color: #ffffff;
}

.btn-warning:hover:not(:disabled) {
  background: #d97706;
}

.btn-danger {
  background: #ef4444;
  color: #ffffff;
}

.btn-danger:hover:not(:disabled) {
  background: #dc2626;
}

.btn-edit {
  background: #3b82f6;
  color: #ffffff;
}

.btn-edit:hover {
  background: #2563eb;
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
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
  .users-table-container,
  .articles-table-container,
  .books-table-container {
    overflow-x: auto;
  }

  .users-table,
  .articles-table,
  .books-table {
    min-width: 800px;
  }

  .stats-bar {
    grid-template-columns: 1fr;
  }
}
</style>
