<template>
  <div class="blog-container">
    <div class="blog-content">
      <div class="articles-table-container">
        <table class="articles-table">
          <thead>
            <tr>
              <th @click="sortBy('title')" class="sortable">
                标题
                <span class="sort-icon" v-if="sortField === 'title'">
                  {{ sortOrder === 'asc' ? '↑' : '↓' }}
                </span>
              </th>
              <th @click="sortBy('publish_date')" class="sortable">
                发布时间
                <span class="sort-icon" v-if="sortField === 'publish_date'">
                  {{ sortOrder === 'asc' ? '↑' : '↓' }}
                </span>
              </th>
              <th @click="sortBy('author')" class="sortable">
                作者
                <span class="sort-icon" v-if="sortField === 'author'">
                  {{ sortOrder === 'asc' ? '↑' : '↓' }}
                </span>
              </th>
              <th>原文地址</th>
              <th @click="sortBy('category')" class="sortable">
                分类
                <span class="sort-icon" v-if="sortField === 'category'">
                  {{ sortOrder === 'asc' ? '↑' : '↓' }}
                </span>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="loading">
              <td colspan="5" class="loading-cell">
                <div class="spinner"></div>
                <span>加载中...</span>
              </td>
            </tr>
            <tr v-else-if="error">
              <td colspan="5" class="error-cell">
                {{ error }}
              </td>
            </tr>
            <tr v-else-if="articles.length === 0">
              <td colspan="5" class="empty-cell">
                暂无文章
              </td>
            </tr>
            <tr v-else v-for="article in articles" :key="article.id" class="article-row">
              <td class="title-cell">
                <span class="article-title">{{ article.title }}</span>
              </td>
              <td class="date-cell">{{ formatDate(article.publish_date) }}</td>
              <td class="author-cell">{{ article.author }}</td>
              <td class="url-cell">
                <a v-if="article.original_url" :href="article.original_url" target="_blank" rel="noopener noreferrer"
                  class="original-link">
                  查看原文 →
                </a>
                <span v-else class="no-url">-</span>
              </td>
              <td class="category-cell">
                <span v-if="article.category" class="category-tag">{{ article.category }}</span>
                <span v-else class="no-category">-</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'

const articles = ref([])
const loading = ref(true)
const error = ref('')
const sortField = ref('publish_date')
const sortOrder = ref('desc')

const fetchArticles = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await fetch(
      `${API_BASE_URL}/api/articles?order_by=${sortField.value}&order=${sortOrder.value}`
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

const sortBy = (field) => {
  if (sortField.value === field) {
    // 切换排序方向
    sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc'
  } else {
    // 新的排序字段，默认降序
    sortField.value = field
    sortOrder.value = 'desc'
  }
  fetchArticles()
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

onMounted(() => {
  fetchArticles()
})
</script>

<style scoped>
.blog-container {
  min-height: calc(100vh - 80px);
  padding: 2rem 1rem;
  background: #ffffff;
}

.blog-content {
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
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 2px solid #e5e7eb;
}

.articles-table th.sortable {
  cursor: pointer;
  user-select: none;
  transition: background-color 0.2s;
  position: relative;
  padding-right: 2rem;
}

.articles-table th.sortable:hover {
  background-color: #f3f4f6;
}

.sort-icon {
  position: absolute;
  right: 0.75rem;
  top: 50%;
  transform: translateY(-50%);
  color: #3b82f6;
  font-weight: bold;
}

.articles-table td {
  padding: 1rem;
  border-bottom: 1px solid #e5e7eb;
  color: #111827;
  font-size: 0.875rem;
}

.articles-table tbody tr:hover {
  background: #f9fafb;
}

.article-title {
  font-weight: 500;
  color: #111827;
}

.title-cell {
  max-width: 400px;
}

.title-cell .article-title {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.date-cell {
  white-space: nowrap;
  color: #6b7280;
}

.author-cell {
  color: #374151;
}

.url-cell {
  white-space: nowrap;
}

.original-link {
  color: #3b82f6;
  text-decoration: none;
  font-weight: 500;
  transition: color 0.2s;
}

.original-link:hover {
  color: #2563eb;
  text-decoration: underline;
}

.no-url {
  color: #9ca3af;
}

.category-cell {
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

.no-category {
  color: #9ca3af;
}

.loading-cell,
.error-cell,
.empty-cell {
  text-align: center;
  padding: 3rem;
  color: #6b7280;
}

.loading-cell {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.spinner {
  width: 20px;
  height: 20px;
  border: 2px solid #e5e7eb;
  border-top-color: #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error-cell {
  color: #ef4444;
}

@media (max-width: 768px) {
  .articles-table-container {
    overflow-x: auto;
  }

  .articles-table {
    min-width: 800px;
  }

  .title-cell {
    max-width: 200px;
  }
}
</style>
