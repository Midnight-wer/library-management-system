<template>
  <div class="category-manage-page">
    <!-- 搜索栏 -->
    <SearchBar :show-keyword="false" @search="loadList" @reset="loadList">
      <template #actions>
        <el-button type="primary" :icon="Plus" @click="openAdd">新增分类</el-button>
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
      :action-width="180"
      @page-change="loadList"
      @size-change="loadList"
    >
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
      width="480px"
      @submit="handleSubmit"
    >
      <el-form-item label="分类名称" prop="categoryName">
        <el-input v-model="form.categoryName" placeholder="请输入分类名称" />
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
import { getCategoryList, addCategory, updateCategory, deleteCategory } from '@/api/category'

const pageNum = ref(1)
const pageSize = ref(10)
const total = ref(0)
const list = ref([])
const loading = ref(false)

const columns = [
  { prop: 'id', label: 'ID', width: 80, align: 'center' },
  { prop: 'categoryName', label: '分类名称', minWidth: 200 },
  { prop: 'createTime', label: '创建时间', width: 180 }
]

const modalVisible = ref(false)
const modalTitle = ref('')
const submitLoading = ref(false)
const isEdit = ref(false)
const editingId = ref(null)
const form = reactive({ categoryName: '' })
const rules = {
  categoryName: [{ required: true, message: '请输入分类名称', trigger: 'blur' }]
}

async function loadList() {
  loading.value = true
  try {
    const res = await getCategoryList()
    // 前端分页
    total.value = res.data.length
    const start = (pageNum.value - 1) * pageSize.value
    list.value = res.data.slice(start, start + pageSize.value)
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.categoryName = ''
  editingId.value = null
}

function openAdd() {
  resetForm()
  isEdit.value = false
  modalTitle.value = '新增分类'
  modalVisible.value = true
}

function openEdit(row) {
  resetForm()
  isEdit.value = true
  modalTitle.value = '编辑分类'
  editingId.value = row.id
  form.categoryName = row.categoryName
  modalVisible.value = true
}

async function handleSubmit(data) {
  submitLoading.value = true
  try {
    if (isEdit.value) {
      await updateCategory(editingId.value, data)
      ElMessage.success('修改成功')
    } else {
      await addCategory(data)
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
    await ElMessageBox.confirm(`确定删除分类"${row.categoryName}"吗?`, '删除确认', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await deleteCategory(row.id)
    ElMessage.success('删除成功')
    loadList()
  } catch (e) {
    if (e !== 'cancel') {
      // 错误已在拦截器提示
    }
  }
}

onMounted(() => {
  loadList()
})
</script>
