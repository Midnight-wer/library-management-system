<template>
  <div class="book-detail-page" v-loading="loading">
    <div v-if="book" class="detail-box card-box">
      <el-row :gutter="32">
        <el-col :xs="24" :sm="10" :md="8">
          <div class="cover-wrap">
            <img v-if="book.cover" :src="book.cover" :alt="book.bookName" class="cover-img" />
            <div v-else class="cover-placeholder">
              <el-icon size="80"><Reading /></el-icon>
              <span>暂无封面</span>
            </div>
          </div>
        </el-col>
        <el-col :xs="24" :sm="14" :md="16">
          <h1 class="title">{{ book.bookName }}</h1>
          <div class="meta">
            <el-tag v-if="available > 0" type="success" size="large" effect="dark">可借 {{ available }} 本</el-tag>
            <el-tag v-else type="info" size="large" effect="dark">已借完</el-tag>
            <span class="meta-item">作者: {{ book.author || '佚名' }}</span>
            <span class="meta-item">ISBN: {{ book.isbn || '-' }}</span>
          </div>
          <el-descriptions :column="2" border class="info-desc">
            <el-descriptions-item label="图书分类">{{ categoryName }}</el-descriptions-item>
            <el-descriptions-item label="总库存">{{ book.totalNum }}</el-descriptions-item>
            <el-descriptions-item label="已借出">{{ book.borrowNum }}</el-descriptions-item>
            <el-descriptions-item label="可借数量">{{ available }}</el-descriptions-item>
          </el-descriptions>
          <div class="intro">
            <h3>图书简介</h3>
            <p>{{ book.introduction || '暂无简介' }}</p>
          </div>
          <div class="actions">
            <el-tooltip :content="borrowDisabledTip" placement="top" :disabled="!borrowDisabled">
              <span class="borrow-btn-wrap">
                <el-button type="primary" size="large" :disabled="borrowDisabled" @click="handleBorrow">
                  {{ available <= 0 ? '已借完' : '提交借阅申请' }}
                </el-button>
              </span>
            </el-tooltip>
            <el-button size="large" @click="$router.back()">返回列表</el-button>
          </div>
        </el-col>
      </el-row>
    </div>
    <!-- 图书不存在/已下架空态 -->
    <div v-else-if="!loading" class="not-found card-box">
      <el-result
        icon="warning"
        title="图书不存在或已下架"
        sub-title="该图书可能已被管理员删除,请返回列表查看其他图书"
      >
        <template #extra>
          <el-button type="primary" @click="router.push('/')">返回图书列表</el-button>
        </template>
      </el-result>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Reading } from '@element-plus/icons-vue'
import { getBookDetail } from '@/api/book'
import { getCategoryList } from '@/api/category'
import { submitBorrow } from '@/api/borrow'
import { useUserStore } from '@/stores/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const book = ref(null)
const categories = ref([])
const loading = ref(false)

const available = computed(() => {
  if (!book.value) return 0
  return (book.value.totalNum || 0) - (book.value.borrowNum || 0)
})
const categoryName = computed(() => {
  if (!book.value || !book.value.categoryId) return '-'
  const c = categories.value.find((item) => item.id === book.value.categoryId)
  return c ? c.categoryName : '-'
})
// 借阅按钮是否禁用及禁用原因提示
const borrowDisabled = computed(() => available.value <= 0 || userStore.isAdmin)
const borrowDisabledTip = computed(() => {
  if (userStore.isAdmin) return '管理员账号用于系统管理,不可借阅图书'
  if (available.value <= 0) return '该书已全部借出,暂无库存'
  return ''
})

async function loadDetail() {
  loading.value = true
  try {
    const res = await getBookDetail(route.params.id)
    book.value = res.data
  } catch (e) {
    // 错误提示已由请求拦截器统一弹出, 此处保持 book 为空以展示"不存在"空态
    book.value = null
  } finally {
    loading.value = false
  }
}

async function loadCategories() {
  const res = await getCategoryList()
  categories.value = res.data
}

async function handleBorrow() {
  try {
    await ElMessageBox.confirm(`确定借阅《${book.value.bookName}》吗?`, '借阅确认', {
      confirmButtonText: '确定借阅',
      cancelButtonText: '取消',
      type: 'info'
    })
    await submitBorrow({ bookId: book.value.id })
    ElMessage.success('借阅申请已提交,等待管理员审核')
    router.push('/profile')
  } catch (e) {
    if (e !== 'cancel') {
      // 错误已在拦截器提示
    }
  }
}

onMounted(() => {
  loadCategories()
  loadDetail()
})
</script>

<style scoped>
.cover-wrap {
  width: 100%;
  min-height: 320px;
  background: #f5f7fa;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}
.cover-img { width: 100%; max-height: 420px; object-fit: contain; }
.cover-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  color: #c0c4cc;
}
.title { font-size: 24px; margin: 0 0 16px; color: #303133; }
.meta { display: flex; align-items: center; gap: 16px; margin-bottom: 16px; flex-wrap: wrap; }
.meta-item { font-size: 14px; color: #606266; }
.info-desc { margin-bottom: 24px; }
.intro h3 { font-size: 16px; margin: 16px 0 8px; color: #303133; }
.intro p { color: #606266; line-height: 1.8; font-size: 14px; }
.actions { margin-top: 32px; display: flex; gap: 12px; }
</style>
