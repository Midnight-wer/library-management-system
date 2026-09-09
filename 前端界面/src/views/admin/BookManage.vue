<template>
  <div class="book-manage-page">
    <!-- 搜索栏 -->
    <SearchBar v-model="keyword" keyword-placeholder="图书名称" @search="loadList" @reset="handleReset">
      <template #filters>
        <el-input v-model="author" placeholder="作者" clearable style="width: 160px" @keyup.enter="loadList" />
        <el-select v-model="categoryId" placeholder="分类" clearable style="width: 160px" @change="loadList">
          <el-option v-for="c in categories" :key="c.id" :label="c.categoryName" :value="c.id" />
        </el-select>
      </template>
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="openAdd">新增图书</el-button>
      </template>
    </SearchBar>

    <!-- 表格 -->
    <CommonTable
      :columns="columns"
      :table-data="list"
      :total="total"
      :loading="loading"
      v-model:current-page="pageNum"
      v-model:page-size="pageSize"
      :action-width="200"
      @page-change="loadList"
      @size-change="loadList"
    >
      <template #coverSlot="{ row }">
        <el-image
          v-if="row.cover"
          :src="row.cover"
          style="width: 50px; height: 50px; border-radius: 4px"
          fit="cover"
          :preview-src-list="[row.cover]"
          preview-teleported
        />
        <span v-else style="color: #c0c4cc">无</span>
      </template>
      <template #categorySlot="{ row }">
        {{ getCategoryName(row.categoryId) }}
      </template>
      <template #numSlot="{ row }">
        <span>{{ row.borrowNum || 0 }} / {{ row.totalNum || 0 }}</span>
      </template>
      <template #actions="{ row }">
        <el-button link type="primary" :icon="Edit" @click="openEdit(row)">编辑</el-button>
        <el-button link type="danger" :icon="Delete" @click="handleDelete(row)">删除</el-button>
      </template>
    </CommonTable>

    <!-- 新增/编辑弹窗 -->
    <ModalForm
      v-model="modalVisible"
      :title="modalTitle"
      :model-data="form"
      :rules="rules"
      :submit-loading="submitLoading"
      width="640px"
      @submit="handleSubmit"
    >
      <el-form-item label="图书名称" prop="bookName">
        <el-input v-model="form.bookName" placeholder="请输入图书名称" />
      </el-form-item>
      <el-form-item label="作者" prop="author">
        <el-input v-model="form.author" placeholder="请输入作者" />
      </el-form-item>
      <el-form-item label="ISBN" prop="isbn">
        <el-input v-model="form.isbn" placeholder="请输入ISBN(唯一)" />
      </el-form-item>
      <el-form-item label="图书分类" prop="categoryId">
        <el-select v-model="form.categoryId" placeholder="请选择分类" clearable style="width: 100%">
          <el-option v-for="c in categories" :key="c.id" :label="c.categoryName" :value="c.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="图书封面" prop="cover">
        <el-upload
          class="cover-uploader"
          :show-file-list="false"
          :http-request="handleCoverUpload"
          accept="image/*"
        >
          <img v-if="form.cover" :src="form.cover" class="cover-preview" />
          <div v-else class="cover-placeholder">
            <el-icon size="28"><Plus /></el-icon>
            <span>上传封面</span>
          </div>
        </el-upload>
        <el-button v-if="form.cover" link type="danger" @click="form.cover = ''">移除</el-button>
      </el-form-item>
      <el-form-item label="总库存" prop="totalNum">
        <el-input-number v-model="form.totalNum" :min="1" :max="9999" />
      </el-form-item>
      <el-form-item label="图书简介" prop="introduction">
        <el-input v-model="form.introduction" type="textarea" :rows="3" placeholder="请输入图书简介" />
      </el-form-item>
    </ModalForm>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import SearchBar from '@/components/SearchBar.vue'
import CommonTable from '@/components/CommonTable.vue'
import ModalForm from '@/components/ModalForm.vue'
import { getBookList, addBook, updateBook, deleteBook } from '@/api/book'
import { getCategoryList } from '@/api/category'
import { uploadFile } from '@/api/file'

const keyword = ref('')
const author = ref('')
const categoryId = ref('')
const pageNum = ref(1)
const pageSize = ref(10)
const total = ref(0)
const list = ref([])
const loading = ref(false)
const categories = ref([])

const columns = [
  { prop: 'bookName', label: '图书名称', minWidth: 160 },
  { prop: 'author', label: '作者', width: 120 },
  { prop: 'isbn', label: 'ISBN', width: 140 },
  { prop: 'categoryId', label: '分类', width: 110, slot: 'categorySlot' },
  { prop: 'cover', label: '封面', width: 90, slot: 'coverSlot', align: 'center' },
  { prop: 'borrowNum', label: '已借/总数', width: 100, slot: 'numSlot', align: 'center' },
  { prop: 'introduction', label: '简介', minWidth: 180 }
]

// 弹窗
const modalVisible = ref(false)
const modalTitle = ref('')
const submitLoading = ref(false)
const isEdit = ref(false)
const editingId = ref(null)
const form = reactive({
  bookName: '', author: '', isbn: '', categoryId: null,
  cover: '', totalNum: 1, introduction: ''
})
const rules = {
  bookName: [{ required: true, message: '请输入图书名称', trigger: 'blur' }],
  totalNum: [{ required: true, message: '请输入总库存', trigger: 'blur' }]
}

function getCategoryName(id) {
  if (!id) return '-'
  const c = categories.value.find((item) => item.id === id)
  return c ? c.categoryName : '-'
}

async function loadCategories() {
  const res = await getCategoryList()
  categories.value = res.data
}

async function loadList() {
  loading.value = true
  try {
    const res = await getBookList({
      pageNum: pageNum.value,
      pageSize: pageSize.value,
      bookName: keyword.value || undefined,
      author: author.value || undefined,
      categoryId: categoryId.value || undefined
    })
    list.value = res.data.records
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
  loadList()
}

function resetForm() {
  form.bookName = ''
  form.author = ''
  form.isbn = ''
  form.categoryId = null
  form.cover = ''
  form.totalNum = 1
  form.introduction = ''
  editingId.value = null
}

function openAdd() {
  resetForm()
  isEdit.value = false
  modalTitle.value = '新增图书'
  modalVisible.value = true
}

function openEdit(row) {
  resetForm()
  isEdit.value = true
  modalTitle.value = '编辑图书'
  editingId.value = row.id
  Object.keys(form).forEach((key) => {
    if (row[key] !== undefined) form[key] = row[key]
  })
  modalVisible.value = true
}

async function handleCoverUpload({ file }) {
  try {
    const res = await uploadFile(file)
    form.cover = res.data.url
  } catch (e) {
    // 错误已在拦截器提示
  }
}

async function handleSubmit(data) {
  submitLoading.value = true
  try {
    if (isEdit.value) {
      await updateBook(editingId.value, data)
      ElMessage.success('修改成功')
    } else {
      await addBook(data)
      ElMessage.success('新增成功')
    }
    modalVisible.value = false
    loadList()
  } finally {
    submitLoading.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除《${row.bookName}》吗?`, '删除确认', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await deleteBook(row.id)
    ElMessage.success('删除成功')
    loadList()
  } catch (e) {
    if (e !== 'cancel') {
      // 错误已在拦截器提示
    }
  }
}

onMounted(() => {
  loadCategories()
  loadList()
})
</script>

<style scoped>
.cover-uploader {
  display: inline-block;
  vertical-align: middle;
  margin-right: 12px;
}
.cover-preview {
  width: 80px;
  height: 100px;
  object-fit: cover;
  border-radius: 4px;
  border: 1px solid #dcdfe6;
}
.cover-placeholder {
  width: 80px;
  height: 100px;
  border: 1px dashed #dcdfe6;
  border-radius: 4px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  color: #909399;
  cursor: pointer;
}
.cover-placeholder:hover { border-color: #409eff; color: #409eff; }
</style>
