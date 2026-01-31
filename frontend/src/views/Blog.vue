<template>
  <div class="blog-container">
    <div class="blog-content">
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
      <div v-else-if="articles.length === 0" class="empty-state">
        暂无文章
      </div>

      <!-- 文章卡片网格 - 两列并排，64px间隙 -->
      <div v-else class="articles-grid">
        <div 
          v-for="article in articles" 
          :key="article.id" 
          class="article-card"
          @click="goToDetail(article)"
        >
          <!-- 封面图片 - 2:1 比例 -->
          <div class="article-cover">
            <img 
              v-if="article.cover_image" 
              :src="getCoverImageUrl(article.cover_image)" 
              :alt="article.title"
              class="cover-image"
              @error="handleImageError"
            />
            <div v-else class="no-cover">
              <span>无封面</span>
            </div>
          </div>

          <!-- 文章信息 -->
          <div class="article-info">
            <h2 class="article-title">{{ article.title }}</h2>
            <div class="article-meta">
              <div class="article-author">
                <span class="author-name">{{ article.author }}</span>
              </div>
              <div class="article-date">
                <span class="date-value">{{ formatDate(article.publish_date) }}</span>
              </div>
            </div>
            <!-- 文章摘要 -->
            <div v-if="article.excerpt" class="article-excerpt">
              <p>{{ article.excerpt }}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'
const router = useRouter()

const articles = ref([])
const loading = ref(true)
const error = ref('')

const fetchArticles = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await fetch(
      `${API_BASE_URL}/api/articles?order_by=publish_date&order=desc`
    )

    if (!response.ok) {
      let errorMsg = '获取文章列表失败'
      try {
        const errorData = await response.json()
        errorMsg = errorData.detail || errorMsg
      } catch (e) {
        errorMsg = `服务器错误: ${response.status} ${response.statusText}`
      }
      throw new Error(errorMsg)
    }

    const data = await response.json()
    articles.value = data
  } catch (err) {
    // 处理网络错误
    if (err instanceof TypeError && err.message === 'Failed to fetch') {
      error.value = '无法连接到服务器，请检查后端服务是否运行'
    } else {
      error.value = err.message || '加载文章列表失败'
    }
    console.error('获取文章列表错误:', err)
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

const goToDetail = (article) => {
  // 第一篇文章跳转到详情页
  if (article.id === 1) {
    router.push(`/blog/${article.id}`)
  }
}

onMounted(() => {
  fetchArticles()
})
</script>

<style scoped>
.blog-container {
  min-height: calc(100vh - 80px);
  padding: 3.2rem 1.6rem;
  background: #ffffff;
  display: flex;
  justify-content: center;
  align-items: flex-start;
}

.blog-content {
  width: 100%;
  max-width: 960px;
  margin: 0 auto;
}

/* 文章网格 - 两列并排，64px间隙 */
.articles-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 64px;
  justify-items: stretch;
}

/* 文章卡片 */
.article-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  overflow: hidden;
  transition: all 0.2s;
  display: flex;
  flex-direction: column;
  width: 100%;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  cursor: pointer;
}

.article-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
  z-index: 1;
}

/* 封面 - 2:1 比例 */
.article-cover {
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

/* 文章信息 */
.article-info {
  padding: 1.2rem;
  flex: 1;
  display: flex;
  flex-direction: column;
}

.article-title {
  font-size: 1.2rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 0.8rem 0;
  line-height: 1.4;
}

.article-meta {
  margin-bottom: 0.8rem;
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.article-author,
.article-date {
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

/* 文章摘要 */
.article-excerpt {
  margin-top: auto;
  padding-top: 0.8rem;
  border-top: 1px solid #e5e7eb;
}

.article-excerpt p {
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
  .blog-container {
    padding: 1.6rem 0.8rem;
  }

  .articles-grid {
    grid-template-columns: 1fr;
    gap: 1.6rem;
  }

  .article-card {
    border-radius: 12px;
    border: 1px solid #e5e7eb;
  }

  .article-info {
    padding: 0.8rem;
  }

  .article-title {
    font-size: 1rem;
  }
}
</style>
