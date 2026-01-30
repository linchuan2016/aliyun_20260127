<template>
    <div class="my-container">
        <div class="my-header">
            <h1 class="my-title">我的</h1>
            <p class="my-subtitle">欢迎回来，{{ user?.username }}！</p>
        </div>

        <div class="my-content">
            <!-- 备忘录部分 -->
            <div class="memo-section">
                <div class="section-header">
                    <h2 class="section-title">备忘录</h2>
                    <button @click="showCreateModal = true" class="btn-create">
                        <span>+</span> 新建备忘录
                    </button>
                </div>

                <div v-if="loading" class="loading">
                    <div class="spinner"></div>
                    <p>加载中...</p>
                </div>

                <div v-else-if="error" class="error-message">
                    {{ error }}
                </div>

                <div v-else-if="memos.length === 0" class="empty-state">
                    <p>还没有备忘录，点击"新建备忘录"开始记录吧！</p>
                </div>

                <div v-else class="memos-grid">
                    <div v-for="memo in memos" :key="memo.id" :class="['memo-card', { 'pinned': memo.is_pinned }]"
                        @click="editMemo(memo)">
                        <div class="memo-header">
                            <h3 class="memo-title">{{ memo.title }}</h3>
                            <div class="memo-actions">
                                <button @click.stop="togglePin(memo)"
                                    :class="['btn-icon', { 'pinned': memo.is_pinned }]"
                                    :title="memo.is_pinned ? '取消置顶' : '置顶'">
                                    📌
                                </button>
                                <button @click.stop="deleteMemo(memo)" class="btn-icon btn-delete" title="删除">
                                    🗑️
                                </button>
                            </div>
                        </div>
                        <p class="memo-content">{{ memo.content || '无内容' }}</p>
                        <div class="memo-footer">
                            <span class="memo-date">{{ formatDate(memo.updated_at || memo.created_at) }}</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- 创建/编辑备忘录模态框 -->
        <div v-if="showCreateModal || editingMemo" class="modal-overlay" @click="closeModal">
            <div class="modal-content" @click.stop>
                <div class="modal-header">
                    <h3>{{ editingMemo ? '编辑备忘录' : '新建备忘录' }}</h3>
                    <button @click="closeModal" class="btn-close">×</button>
                </div>
                <div class="modal-body">
                    <div class="form-group">
                        <label>标题</label>
                        <input v-model="memoForm.title" type="text" placeholder="请输入标题" maxlength="200" />
                    </div>
                    <div class="form-group">
                        <label>内容</label>
                        <textarea v-model="memoForm.content" placeholder="请输入内容" rows="6"></textarea>
                    </div>
                    <div class="form-group">
                        <label class="checkbox-label">
                            <input v-model="memoForm.is_pinned" type="checkbox" />
                            <span>置顶</span>
                        </label>
                    </div>
                </div>
                <div class="modal-footer">
                    <button @click="closeModal" class="btn-cancel">取消</button>
                    <button @click="saveMemo" class="btn-save" :disabled="!memoForm.title.trim()">
                        {{ editingMemo ? '保存' : '创建' }}
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useAuth } from '../composables/useAuth'
import { useRouter } from 'vue-router'

const router = useRouter()
const { user, token } = useAuth()

// 生产环境使用相对路径，开发环境使用完整URL
const API_BASE_URL = import.meta.env.PROD ? '' : 'http://127.0.0.1:8000'

const memos = ref([])
const loading = ref(true)
const error = ref('')
const showCreateModal = ref(false)
const editingMemo = ref(null)

const memoForm = ref({
    title: '',
    content: '',
    is_pinned: false
})

// 检查是否已登录
onMounted(() => {
    if (!token.value) {
        router.push('/login')
        return
    }
    fetchMemos()
})

const fetchMemos = async () => {
    loading.value = true
    error.value = ''

    try {
        const response = await fetch(`${API_BASE_URL}/api/memos`, {
            headers: {
                'Authorization': `Bearer ${token.value}`,
            },
        })

        if (!response.ok) {
            if (response.status === 401) {
                router.push('/login')
                return
            }
            throw new Error('获取备忘录失败')
        }

        const data = await response.json()
        memos.value = data
    } catch (err) {
        error.value = err.message || '加载备忘录失败'
    } finally {
        loading.value = false
    }
}

const editMemo = (memo) => {
    editingMemo.value = memo
    memoForm.value = {
        title: memo.title,
        content: memo.content || '',
        is_pinned: memo.is_pinned
    }
}

const closeModal = () => {
    showCreateModal.value = false
    editingMemo.value = null
    memoForm.value = {
        title: '',
        content: '',
        is_pinned: false
    }
}

const saveMemo = async () => {
    if (!memoForm.value.title.trim()) {
        return
    }

    try {
        let response
        if (editingMemo.value) {
            // 更新备忘录
            response = await fetch(`${API_BASE_URL}/api/memos/${editingMemo.value.id}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token.value}`,
                },
                body: JSON.stringify(memoForm.value),
            })
        } else {
            // 创建备忘录
            response = await fetch(`${API_BASE_URL}/api/memos`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token.value}`,
                },
                body: JSON.stringify(memoForm.value),
            })
        }

        if (!response.ok) {
            throw new Error(editingMemo.value ? '更新失败' : '创建失败')
        }

        await fetchMemos()
        closeModal()
    } catch (err) {
        alert(err.message || '操作失败')
    }
}

const togglePin = async (memo) => {
    try {
        const response = await fetch(`${API_BASE_URL}/api/memos/${memo.id}`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token.value}`,
            },
            body: JSON.stringify({ is_pinned: !memo.is_pinned }),
        })

        if (!response.ok) {
            throw new Error('操作失败')
        }

        await fetchMemos()
    } catch (err) {
        alert(err.message || '操作失败')
    }
}

const deleteMemo = async (memo) => {
    if (!confirm(`确定要删除备忘录"${memo.title}"吗？`)) {
        return
    }

    try {
        const response = await fetch(`${API_BASE_URL}/api/memos/${memo.id}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${token.value}`,
            },
        })

        if (!response.ok) {
            throw new Error('删除失败')
        }

        await fetchMemos()
    } catch (err) {
        alert(err.message || '删除失败')
    }
}

const formatDate = (dateString) => {
    if (!dateString) return ''
    const date = new Date(dateString)
    return date.toLocaleString('zh-CN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    })
}
</script>

<style scoped>
.my-container {
    min-height: calc(100vh - 80px);
    padding: 2rem 1rem;
    background: #ffffff;
    background-image:
        radial-gradient(at 0% 0%, rgba(59, 130, 246, 0.03) 0px, transparent 50%),
        radial-gradient(at 100% 100%, rgba(139, 92, 246, 0.03) 0px, transparent 50%);
}

.my-header {
    max-width: 1600px;
    margin: 0 auto 2rem;
    text-align: center;
}

.my-title {
    font-size: 2.5rem;
    font-weight: 700;
    color: #111827;
    margin-bottom: 0.5rem;
}

.my-subtitle {
    font-size: 1rem;
    color: #6b7280;
}

.my-content {
    max-width: 1600px;
    margin: 0 auto;
}

.memo-section {
    background: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 12px;
    padding: 2rem;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
}

.section-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 1.5rem;
}

.section-title {
    font-size: 1.5rem;
    font-weight: 600;
    color: #111827;
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

.btn-create span {
    font-size: 1.25rem;
    line-height: 1;
}

.loading,
.error-message,
.empty-state {
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
    to {
        transform: rotate(360deg);
    }
}

.error-message {
    color: #ef4444;
}

.empty-state {
    color: #6b7280;
}

.memos-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: 1rem;
}

.memo-card {
    background: #ffffff;
    border: 1px solid #e5e7eb;
    border-radius: 8px;
    padding: 1rem;
    cursor: pointer;
    transition: all 0.3s;
    position: relative;
}

.memo-card:hover {
    border-color: #3b82f6;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
    transform: translateY(-2px);
}

.memo-card.pinned {
    border-color: #f59e0b;
    background: #fffbeb;
}

.memo-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 0.75rem;
}

.memo-title {
    font-size: 1.125rem;
    font-weight: 600;
    color: #111827;
    margin: 0;
    flex: 1;
}

.memo-actions {
    display: flex;
    gap: 0.5rem;
}

.btn-icon {
    background: transparent;
    border: none;
    font-size: 1rem;
    cursor: pointer;
    padding: 0.25rem;
    opacity: 0.6;
    transition: all 0.2s;
}

.btn-icon:hover {
    opacity: 1;
}

.btn-icon.pinned {
    opacity: 1;
}

.memo-content {
    color: #6b7280;
    font-size: 0.875rem;
    line-height: 1.5;
    margin: 0 0 0.75rem 0;
    display: -webkit-box;
    -webkit-line-clamp: 3;
    line-clamp: 3;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.memo-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: 0.75rem;
    border-top: 1px solid #f3f4f6;
}

.memo-date {
    font-size: 0.75rem;
    color: #9ca3af;
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
}

.modal-content {
    background: #ffffff;
    border-radius: 12px;
    width: 90%;
    max-width: 600px;
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

.checkbox-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
}

.checkbox-label input[type="checkbox"] {
    width: auto;
    margin: 0;
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
    .memos-grid {
        grid-template-columns: 1fr;
    }

    .section-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 1rem;
    }
}
</style>
