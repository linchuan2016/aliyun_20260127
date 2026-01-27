# 直接修复服务器上的文件（GitHub 连接失败时）

如果 `git pull` 失败，可以直接在服务器上修改文件。

## 方法1：直接修改 App.vue（推荐）

```bash
# 1. 编辑前端文件
vi /var/www/my-fullstack-app/frontend/src/App.vue
```

找到这段代码：
```javascript
const response = await fetch('http://127.0.0.1:8000/api/data');
```

改为：
```javascript
const response = await fetch('/api/data');
```

**完整文件内容应该是：**
```vue
<script setup>
import { ref, onMounted } from 'vue'

const msg = ref('等待数据中...')

onMounted(async () => {
  try {
    const response = await fetch('/api/data');
    const data = await response.json()
    msg.value = data.message
  } catch (error) {
    msg.value = "无法连接到后端！"
    console.error(error)
  }
})
</script>

<template>
  <div style="text-align: center; margin-top: 50px;">
    <h1>Lin</h1>
    <p style="font-size: 24px; color: #42b983;">
      {{ msg }}
    </p>
  </div>
</template>
```

保存退出（vi: 按 Esc，输入 :wq，回车）

---

## 方法2：使用 sed 命令快速替换

```bash
# 替换 App.vue 中的 API 地址
sed -i "s|http://127.0.0.1:8000/api/data|/api/data|g" /var/www/my-fullstack-app/frontend/src/App.vue

# 或者替换所有包含 127.0.0.1:8000 的地方
sed -i "s|http://127.0.0.1:8000||g" /var/www/my-fullstack-app/frontend/src/App.vue
```

---

## 修改后重新构建

```bash
# 1. 进入前端目录
cd /var/www/my-fullstack-app/frontend

# 2. 重新构建
npm run build

# 3. 重启 Nginx
sudo systemctl restart nginx

# 4. 验证
ls -lth dist/
```

---

## 一键修复命令

```bash
# 修改文件
sed -i "s|http://127.0.0.1:8000/api/data|/api/data|g" /var/www/my-fullstack-app/frontend/src/App.vue && \
sed -i "s|\${apiUrl}/api/data|/api/data|g" /var/www/my-fullstack-app/frontend/src/App.vue && \
sed -i "s|apiUrl.*api/data|/api/data|g" /var/www/my-fullstack-app/frontend/src/App.vue && \
cd /var/www/my-fullstack-app/frontend && \
npm run build && \
sudo systemctl restart nginx && \
echo "修复完成！"
```

---

## 验证修复

```bash
# 检查构建后的文件
grep -r "127.0.0.1:8000" /var/www/my-fullstack-app/frontend/dist/ || echo "✓ 未找到旧地址，修复成功！"

# 检查新代码
grep -r "/api/data" /var/www/my-fullstack-app/frontend/dist/ && echo "✓ 找到新地址，修复成功！"
```

