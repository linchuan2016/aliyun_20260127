<template>
  <div class="book-container">
    <div class="book-content">
      <!-- 加载状态 -->
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <span>加载中...</span>
      </div>

      <!-- 错误状态 -->
      <div v-else-if="error" class="error-state">
        {{ error }}
      </div>

      <!-- 空状态 -->
      <div v-else-if="books.length === 0" class="empty-state">
        暂无书籍
      </div>

      <!-- 书籍卡片网格 - 两列并排，无间隙 -->
      <div v-else class="books-grid">
        <div 
          v-for="book in books" 
          :key="book.id" 
          class="book-card"
        >
          <!-- 封面图片 - 2:1 比例 -->
          <div class="book-cover">
            <img 
              v-if="book.cover_image" 
              :src="getCoverImageUrl(book.cover_image)" 
              :alt="book.title"
              class="cover-image"
              @error="handleImageError"
            />
            <div v-else class="no-cover">
              <span>无封面</span>
            </div>
          </div>

          <!-- 书籍信息 -->
          <div class="book-info">
            <h2 class="book-title">{{ book.title }}</h2>
            <div class="book-meta">
              <div class="book-author">
                <span class="author-name">{{ book.author }}</span>
              </div>
              <div class="book-date">
                <span class="date-value">{{ formatDate(book.publish_date) }}</span>
              </div>
            </div>
            <!-- 书籍简介 -->
            <div v-if="book.description" class="book-description">
              <p>{{ book.description }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'

const books = ref([])
const loading = ref(true)
const error = ref('')

const fetchBooks = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await fetch(
      `${API_BASE_URL}/api/books?order_by=publish_date&order=desc`
    )

    if (!response.ok) {
      let errorMsg = '获取书籍列表失败'
      try {
        const errorData = await response.json()
        errorMsg = errorData.detail || errorMsg
      } catch (e) {
        errorMsg = `服务器错误: ${response.status} ${response.statusText}`
      }
      throw new Error(errorMsg)
    }

    const data = await response.json()
    books.value = data
  } catch (err) {
    // 处理网络错误
    if (err instanceof TypeError && err.message === 'Failed to fetch') {
      error.value = '无法连接到服务器，请检查后端服务是否运行'
    } else {
      error.value = err.message || '加载书籍列表失败'
    }
    console.error('获取书籍列表错误:', err)
  } finally {
    loading.value = false
  }
}

const getCoverImageUrl = (coverImage) => {
  if (!coverImage) return ''
  // 如果是完整URL，直接返回
  if (coverImage.startsWith('http://') || coverImage.startsWith('https://')) {
    return coverImage
  }
  // 如果是相对路径，在开发环境中加上API地址
  return `${API_BASE_URL}${coverImage}`
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
  const parent = event.target.parentElement
  if (parent && !parent.querySelector('.no-cover')) {
    const noCover = document.createElement('div')
    noCover.className = 'no-cover'
    noCover.innerHTML = '<span>无封面</span>'
    parent.appendChild(noCover)
  }
}

onMounted(() => {
  fetchBooks()
})
</script>

<style scoped>
.book-container {
  min-height: calc(100vh - 80px);
  padding: 3.2rem 1.6rem;
  background: #ffffff;
  display: flex;
  justify-content: center;
  align-items: flex-start;
}

.book-content {
  width: 100%;
  max-width: 960px;
  margin: 0 auto;
}

/* 书籍网格 - 两列并排，64px间隙 */
.books-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 64px;
  justify-items: stretch;
}

/* 书籍卡片 */
.book-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
  width: 100%;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.book-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
  z-index: 1;
}

/* 封面 - 2:1 比例 */
.book-cover {
  width: 100%;
  aspect-ratio: 2 / 1;
  background: #f9fafb;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.cover-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.no-cover {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f3f4f6;
  color: #9ca3af;
  font-size: 0.875rem;
}

/* 书籍信息 */
.book-info {
  padding: 1.2rem;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.book-title {
  font-size: 1.2rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 0.8rem 0;
  line-height: 1.4;
}

.book-meta {
  margin-bottom: 0.8rem;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.book-author,
.book-date {
  display: flex;
  align-items: center;
  font-size: 0.8rem;
}

.author-name {
  color: #6b7280;
}

.date-value {
  color: #6b7280;
}

/* 书籍简介 */
.book-description {
  margin-top: auto;
  padding-top: 0.8rem;
  border-top: 1px solid #e5e7eb;
}

.book-description p {
  font-size: 0.8rem;
  line-height: 1.6;
  color: #6b7280;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* 加载/错误/空状态 */
.loading-state,
.error-state,
.empty-state {
  text-align: center;
  padding: 3.2rem 1.6rem;
  color: #6b7280;
}

.loading-state {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.spinner {
  width: 24px;
  height: 24px;
  border: 3px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-state {
  color: #ef4444;
}

/* 响应式设计 */
@media (max-width: 768px) {
  .book-container {
    padding: 1.6rem 0.8rem;
  }

  .books-grid {
    grid-template-columns: 1fr;
    gap: 1.6rem;
  }

  .book-card {
    border-radius: 12px;
    border: 1px solid #e5e7eb;
  }

  .book-card:first-child,
  .book-card:last-child {
    border-radius: 12px;
    border: 1px solid #e5e7eb;
  }

  .book-info {
    padding: 0.8rem;
  }

  .book-title {
    font-size: 1rem;
  }
}
</style>
