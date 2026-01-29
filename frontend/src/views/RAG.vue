<script setup>
// RAG 向量数据库页面
const vectorDBs = [
  {
    id: 1,
    name: 'Milvus',
    title: 'Milvus',
    description: '开源向量数据库，专为 AI 应用设计，支持大规模向量相似度搜索',
    official_url: 'https://milvus.io',
    image_url: '/icons/milvus.png'
  },
  {
    id: 2,
    name: 'PGVector',
    title: 'PGVector',
    description: 'PostgreSQL 的向量相似度搜索扩展，提供高效的向量存储和检索',
    official_url: 'https://github.com/pgvector/pgvector',
    image_url: '/icons/pgvector.png'
  },
  {
    id: 3,
    name: 'Qdrant',
    title: 'Qdrant',
    description: '高性能向量搜索引擎，专为生产环境优化的向量数据库',
    official_url: 'https://qdrant.tech',
    image_url: '/icons/qdrant.png'
  },
  {
    id: 4,
    name: 'MyScale',
    title: 'MyScale',
    description: '云原生向量数据库，结合 SQL 和向量搜索能力，提供一站式解决方案',
    official_url: 'https://myscale.com',
    image_url: '/icons/myscale.png'
  }
]
</script>

<template>
  <div class="rag-container">
    <!-- 头部 -->
    <header class="rag-header">
      <h1 class="rag-title">RAG 向量数据库</h1>
      <p class="rag-subtitle">专业的向量数据库解决方案</p>
    </header>

    <!-- 向量数据库列表 -->
    <div class="vector-dbs-container">
      <a
        v-for="db in vectorDBs"
        :key="db.id"
        :href="db.official_url"
        target="_blank"
        rel="noopener noreferrer"
        class="vector-db-card"
      >
        <div class="vector-db-image">
          <img :src="db.image_url" :alt="db.title" />
        </div>
        <div class="vector-db-content">
          <h2 class="vector-db-title">{{ db.title }}</h2>
          <p class="vector-db-description">{{ db.description }}</p>
        </div>
      </a>
    </div>
  </div>
</template>

<style scoped>
.rag-container {
  min-height: 100vh;
  background: #ffffff;
  background-image:
    radial-gradient(at 0% 0%, rgba(59, 130, 246, 0.03) 0px, transparent 50%),
    radial-gradient(at 100% 100%, rgba(139, 92, 246, 0.03) 0px, transparent 50%);
  padding: 2rem 1rem;
  position: relative;
  overflow-x: hidden;
}

.rag-header {
  text-align: center;
  margin-bottom: 2rem;
  padding: 2rem 0;
  position: relative;
  z-index: 1;
}

.rag-title {
  font-size: 3rem;
  font-weight: 800;
  background: linear-gradient(135deg, #3b82f6 0%, #8b5cf6 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 0.5rem;
  letter-spacing: -0.02em;
}

.rag-subtitle {
  font-size: 1rem;
  color: #6b7280;
  margin: 0;
  font-weight: 300;
}

.vector-dbs-container {
  max-width: 1600px;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
  position: relative;
  z-index: 1;
}

@media (min-width: 640px) {
  .vector-dbs-container {
    grid-template-columns: repeat(2, 1fr);
    gap: 0.75rem;
  }
}

@media (min-width: 768px) {
  .vector-dbs-container {
    grid-template-columns: repeat(4, 1fr);
    gap: 1rem;
  }
}

@media (min-width: 1024px) {
  .vector-dbs-container {
    grid-template-columns: repeat(4, 1fr);
    gap: 1.25rem;
  }
}

.vector-db-card {
  background: #ffffff;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  overflow: hidden;
  transition: all 0.3s ease;
  display: block;
  text-decoration: none;
  color: inherit;
  cursor: pointer;
}

.vector-db-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.1);
  border-color: #d1d5db;
}

.vector-db-image {
  width: 100%;
  height: 80px;
  overflow: hidden;
  background: #f9fafb;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0.75rem;
}

.vector-db-image img {
  max-width: 50px;
  max-height: 50px;
  object-fit: contain;
  display: block;
  margin: 0 auto;
}

.vector-db-content {
  padding: 0.75rem;
}

.vector-db-title {
  font-size: 1rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 0.5rem;
  line-height: 1.3;
}

.vector-db-description {
  font-size: 0.75rem;
  line-height: 1.4;
  color: #6b7280;
  margin: 0;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

@media (max-width: 768px) {
  .rag-title {
    font-size: 2rem;
  }
  
  .vector-dbs-container {
    grid-template-columns: 1fr;
  }
}
</style>

