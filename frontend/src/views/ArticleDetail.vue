<template>
  <div class="article-detail-container">
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <span>加载中...</span>
    </div>

    <div v-else-if="error" class="error-state">
      {{ error }}
    </div>

    <div v-else-if="article" class="article-detail-content">
      <!-- 返回按钮和原文地址 -->
      <div class="article-header-actions">
        <button @click="goBack" class="back-button">
          ← 返回
        </button>
        <a 
          v-if="article.original_url" 
          :href="article.original_url" 
          target="_blank" 
          rel="noopener noreferrer"
          class="original-link-button"
        >
          查看原文 →
        </a>
      </div>

      <!-- 文章标题 -->
      <h1 class="article-detail-title">{{ article.title }}</h1>
      
      <!-- 文章元信息 -->
      <div class="article-meta-info">
        <span class="meta-item">作者：{{ article.author }}</span>
        <span class="meta-item">发布时间：{{ formatDate(article.publish_date) }}</span>
        <span v-if="article.category" class="meta-item category-item">
          <span class="category-tag">{{ article.category }}</span>
        </span>
      </div>

      <!-- 文章内容（仅中文） -->
      <div class="article-content">
        <div class="content-text" v-html="formatContent(article.content)"></div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'
const route = useRoute()
const router = useRouter()

const article = ref(null)
const loading = ref(true)
const error = ref('')

const fetchArticle = async () => {
  loading.value = true
  error.value = ''

  try {
    const articleId = route.params.id
    const response = await fetch(`${API_BASE_URL}/api/articles/${articleId}`)

    if (!response.ok) {
      if (response.status === 404) {
        throw new Error('文章不存在')
      }
      throw new Error('获取文章失败')
    }

    const data = await response.json()
    article.value = data
  } catch (err) {
    error.value = err.message || '加载文章失败'
    console.error('获取文章错误:', err)
  } finally {
    loading.value = false
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

const formatContent = (content) => {
  if (!content) return ''
  
  // 先处理标题
  let formatted = content.replace(/^## (.*)$/gm, '<h3>$1</h3>')
  
  // 处理列表项（以 * 或 - 开头）
  formatted = formatted.replace(/^[\*\-\•] (.+)$/gm, '<li>$1</li>')
  
  // 将多个换行符分隔的段落转换为p标签
  const paragraphs = formatted.split(/\n\n+/)
  formatted = paragraphs.map(p => {
    p = p.trim()
    if (!p) return ''
    // 如果已经是HTML标签，直接返回
    if (p.startsWith('<')) return p
    // 否则包装在p标签中
    return `<p>${p.replace(/\n/g, '<br>')}</p>`
  }).filter(p => p).join('')
  
  return formatted
}

const goBack = () => {
  router.push('/blog')
}

onMounted(() => {
  fetchArticle()
})
</script>

<style scoped>
.article-detail-container {
  min-height: calc(100vh - 80px);
  padding: 2rem 1rem;
  background: #ffffff;
}

.article-detail-content {
  max-width: 1000px;
  margin: 0 auto;
}

.article-header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.back-button {
  padding: 0.5rem 1rem;
  background: #f3f4f6;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  color: #374151;
  font-size: 0.875rem;
  cursor: pointer;
  transition: all 0.2s;
}

.back-button:hover {
  background: #e5e7eb;
  color: #111827;
}

.original-link-button {
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: #ffffff;
  text-decoration: none;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.2s;
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.original-link-button:hover {
  background: #2563eb;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
}

.article-detail-title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #111827;
  margin: 0 0 1.5rem 0;
  line-height: 1.3;
}

.article-meta-info {
  display: flex;
  gap: 2rem;
  align-items: center;
  margin-bottom: 3rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  flex-wrap: wrap;
}

.meta-item {
  font-size: 0.875rem;
  color: #6b7280;
}

.category-item {
  display: flex;
  align-items: center;
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

/* 文章内容 */
.article-content {
  background: #ffffff;
  padding: 2rem;
  border-radius: 12px;
  border: 1px solid #e5e7eb;
}

.content-text {
  font-size: 1.125rem;
  line-height: 1.8;
  color: #374151;
}

.content-text :deep(p) {
  margin: 0 0 1.5rem 0;
}

.content-text :deep(h3) {
  font-size: 1.5rem;
  font-weight: 600;
  color: #111827;
  margin: 2rem 0 1rem 0;
  padding-bottom: 0.5rem;
  border-bottom: 2px solid #e5e7eb;
}

.content-text :deep(strong) {
  font-weight: 600;
  color: #111827;
}

.content-text :deep(li) {
  margin: 0.75rem 0;
  padding-left: 1.5rem;
  position: relative;
  list-style: none;
}

.content-text :deep(li):before {
  content: "•";
  position: absolute;
  left: 0;
  color: #3b82f6;
  font-weight: bold;
}

/* 加载/错误状态 */
.loading-state,
.error-state {
  text-align: center;
  padding: 4rem 2rem;
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
  .article-detail-container {
    padding: 1rem 0.5rem;
  }

  .article-detail-title {
    font-size: 1.75rem;
  }

  .article-meta-info {
    flex-direction: column;
    gap: 0.5rem;
    align-items: flex-start;
  }

  .article-content {
    padding: 1.5rem;
  }

  .content-text {
    font-size: 1rem;
  }

  .article-header-actions {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }

  .original-link-button {
    text-align: center;
  }
}
</style>
