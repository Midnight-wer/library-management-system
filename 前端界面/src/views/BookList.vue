<template>
  <div class="book-list-page">
    <!-- 搜索栏 -->
    <SearchBar v-model="keyword" :show-keyword="true" keyword-placeholder="请输入图书名称" @search="loadBooks" @reset="handleReset">
      <template #filters>
        <el-select v-model="categoryId" placeholder="选择分类" clearable style="width: 160px">
          <el-option v-for="c in categories" :key="c.id" :label="c.categoryName" :value="c.id" />
        </el-select>
        <el-input v-model="author" placeholder="作者" clearable style="width: 160px" @keyup.enter="loadBooks" />
      </template>
    </SearchBar>

    <!-- 图书卡片 -->
    <div v-loading="loading" class="book-grid card-box">
      <div v-if="bookList.length === 0 && !loading" class="empty-tip">
        <el-empty description="暂无图书" />
      </div>
      <el-row :gutter="16">
        <el-col v-for="book in bookList" :key="book.id" :xs="12" :sm="8" :md="6" :lg="6">
          <el-card class="book-card" :body-style="{ padding: '0' }" shadow="hover">
            <div class="book-cover" @click="goDetail(book.id)">
              <img v-if="book.cover" :src="book.cover" :alt="book.bookName" />
              <div v-else class="cover-placeholder">
                <el-icon size="40"><Reading /></el-icon>
                <span>暂无封面</span>
              </div>
              <div class="book-status">
                <el-tag v-if="available(book) > 0" type="success" size="small" effect="dark">可借 {{ available(book) }}</el-tag>
                <el-tag v-else type="info" size="small" effect="dark">已借完</el-tag>
              </div>
            </div>
            <div class="book-info">
              <h3 class="book-name" :title="book.bookName" @click="goDetail(book.id)">{{ book.bookName }}</h3>
              <p class="book-author">{{ book.author || '佚名' }}</p>
              <p class="book-intro">{{ book.introduction || '暂无简介' }}</p>
              <div class="book-actions">
                <el-button size="small" @click="goDetail(book.id)">查看详情</el-button>
                <el-button
                  v-if="!userStore.isAdmin"
                  type="primary"
                  size="small"
                  :disabled="available(book) <= 0"
                  @click="handleBorrow(book)"
                >借阅</el-button>
              </div>
            </div>
          </el-card>
        </el-col>
      </el-row>
      <!-- 分页 -->
      <div class="pagination-wrap">
        <el-pagination
          v-model:current-page="pageNum"
          v-model:page-size="pageSize"
          :page-sizes="[12, 24, 48]"
          :total="total"
          layout="total, sizes, prev, pager, next, jumper"
          background
          @current-change="loadBooks"
          @size-change="loadBooks"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Reading } from '@element-plus/icons-vue'
import SearchBar from '@/components/SearchBar.vue'
import { getBookList } from '@/api/book'
import { getCategoryList } from '@/api/category'
import { submitBorrow } from '@/api/borrow'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()

const keyword = ref('')
const author = ref('')
const categoryId = ref('')
const pageNum = ref(1)
const pageSize = ref(12)
const total = ref(0)

const bookList = ref([])
const categories = ref([])
const loading = ref(false)

// 可借数量
function available(book) {
  const total = book.totalNum || 0
  const borrow = book.borrowNum || 0
  return total - borrow
}

async function loadCategories() {
  const res = await getCategoryList()
  categories.value = res.data
}

async function loadBooks() {
  loading.value = true
  try {
    const res = await getBookList({
      pageNum: pageNum.value,
      pageSize: pageSize.value,
      bookName: keyword.value || undefined,
      author: author.value || undefined,
      categoryId: categoryId.value || undefined
    })
    bookList.value = res.data.records
    total.value = Number(res.data.total)
  } finally {
    loading.value = false
  }
}

function handleReset() {
  keyword.value = ''
  author.value = ''
  categoryId.value = ''
  pageNum.value = 1
  loadBooks()
}

function goDetail(id) {
  router.push(`/book/${id}`)
}

async function handleBorrow(book) {
  try {
    await ElMessageBox.confirm(`确定借阅《${book.bookName}》吗?`, '借阅确认', {
      confirmButtonText: '确定借阅',
      cancelButtonText: '取消',
      type: 'info'
    })
    await submitBorrow({ bookId: book.id })
    ElMessage.success('借阅申请已提交,等待管理员审核')
  } catch (e) {
    if (e !== 'cancel') {
      // 错误已在拦截器提示
    }
  }
}

onMounted(() => {
  loadCategories()
  loadBooks()
})
</script>

<style scoped>
.book-grid { min-height: 200px; }
.empty-tip { padding: 40px 0; }
.book-card { margin-bottom: 16px; border-radius: 8px; overflow: hidden; transition: transform 0.2s; }
.book-card:hover { transform: translateY(-4px); }
.book-cover {
  position: relative;
  height: 200px;
  background: #f5f7fa;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  overflow: hidden;
}
.book-cover img { width: 100%; height: 100%; object-fit: cover; }
.cover-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  color: #c0c4cc;
}
.book-status { position: absolute; top: 8px; right: 8px; }
.book-info { padding: 12px; }
.book-name {
  font-size: 15px;
  margin: 0 0 6px;
  cursor: pointer;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  color: #303133;
}
.book-name:hover { color: #409eff; }
.book-author { font-size: 12px; color: #909399; margin: 0 0 4px; }
.book-intro {
  font-size: 12px;
  color: #909399;
  margin: 0 0 8px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 32px;
}
.book-actions { display: flex; gap: 8px; }
</style>
