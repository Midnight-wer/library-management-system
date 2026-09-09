<template>
  <div class="user-manage-page">
    <!-- 搜索栏 -->
    <SearchBar v-model="keyword" keyword-placeholder="账号/昵称/手机号" @search="loadList" @reset="handleReset">
      <template #filters>
        <el-select v-model="role" placeholder="角色" clearable style="width: 140px" @change="loadList">
          <el-option label="管理员" value="admin" />
          <el-option label="普通用户" value="user" />
        </el-select>
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
      <template #avatarSlot="{ row }">
        <el-avatar :size="36" :src="row.avatar || ''">
          <el-icon><User /></el-icon>
        </el-avatar>
      </template>
      <template #roleSlot="{ row }">
        <el-tag :type="row.role === 'admin' ? 'danger' : 'success'">
          {{ row.role === 'admin' ? '管理员' : '普通用户' }}
        </el-tag>
      </template>
      <template #actions="{ row }">
        <el-button link type="primary" :icon="Edit" @click="openEdit(row)">编辑</el-button>
        <el-button
          v-if="row.role !== 'admin'"
          link
          type="danger"
          :icon="Delete"
          @click="handleDelete(row)"
        >删除</el-button>
      </template>
    </CommonTable>

    <!-- 编辑弹窗 -->
    <ModalForm
      v-model="modalVisible"
      :title="modalTitle"
      :model-data="form"
      :rules="rules"
      :submit-loading="submitLoading"
      width="520px"
      @submit="handleSubmit"
    >
      <el-form-item label="账号">
        <el-input :model-value="form.username" disabled />
      </el-form-item>
      <el-form-item label="角色">
        <el-tag :type="form.role === 'admin' ? 'danger' : 'success'">
          {{ form.role === 'admin' ? '管理员' : '普通用户' }}
        </el-tag>
      </el-form-item>
      <el-form-item label="昵称" prop="nickname">
        <el-input v-model="form.nickname" placeholder="请输入昵称" />
      </el-form-item>
      <el-form-item label="手机号" prop="phone">
        <el-input v-model="form.phone" placeholder="请输入手机号" />
      </el-form-item>
      <el-form-item label="头像" prop="avatar">
        <el-upload
          class="avatar-uploader"
          :show-file-list="false"
          :http-request="handleAvatarUpload"
          accept="image/*"
        >
          <el-avatar :size="80" :src="form.avatar">
            <el-icon size="28"><User /></el-icon>
          </el-avatar>
        </el-upload>
        <el-button v-if="form.avatar" link type="danger" @click="form.avatar = ''">移除</el-button>
      </el-form-item>
    </ModalForm>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { User, Edit, Delete } from '@element-plus/icons-vue'
import SearchBar from '@/components/SearchBar.vue'
import CommonTable from '@/components/CommonTable.vue'
import ModalForm from '@/components/ModalForm.vue'
import { getUserList, updateUser, deleteUser } from '@/api/user'
import { uploadFile } from '@/api/file'

const keyword = ref('')
const role = ref('')
const pageNum = ref(1)
const pageSize = ref(10)
const total = ref(0)
const list = ref([])
const loading = ref(false)

const columns = [
  { prop: 'avatar', label: '头像', width: 80, slot: 'avatarSlot', align: 'center' },
  { prop: 'username', label: '账号', width: 140 },
  { prop: 'nickname', label: '昵称', width: 140 },
  { prop: 'phone', label: '手机号', width: 140 },
  { prop: 'role', label: '角色', width: 110, slot: 'roleSlot', align: 'center' },
  { prop: 'createTime', label: '注册时间', width: 170 },
  { prop: 'updateTime', label: '更新时间', width: 170 }
]

const modalVisible = ref(false)
const modalTitle = ref('')
const submitLoading = ref(false)
const editingId = ref(null)
const form = reactive({
  username: '', role: 'user', nickname: '', phone: '', avatar: ''
})
const rules = {
  nickname: [{ max: 50, message: '昵称长度不能超过50', trigger: 'blur' }],
  phone: [{ max: 20, message: '手机号长度不正确', trigger: 'blur' }]
}

async function loadList() {
  loading.value = true
  try {
    const res = await getUserList({
      pageNum: pageNum.value,
      pageSize: pageSize.value,
      keyword: keyword.value || undefined,
      role: role.value || undefined
    })
    list.value = res.data.records
    total.value = Number(res.data.total)
  } finally {
    loading.value = false
  }
}

function handleReset() {
  keyword.value = ''
  role.value = ''
  pageNum.value = 1
  loadList()
}

function openEdit(row) {
  editingId.value = row.id
  form.username = row.username
  form.role = row.role
  form.nickname = row.nickname
  form.phone = row.phone
  form.avatar = row.avatar
  modalTitle.value = '编辑用户'
  modalVisible.value = true
}

async function handleAvatarUpload({ file }) {
  try {
    const res = await uploadFile(file)
    form.avatar = res.data.url
  } catch (e) {
    // 错误已在拦截器提示
  }
}

async function handleSubmit(data) {
  submitLoading.value = true
  try {
    await updateUser(editingId.value, {
      nickname: data.nickname,
      phone: data.phone,
      avatar: data.avatar
    })
    ElMessage.success('修改成功')
    modalVisible.value = false
    loadList()
  } finally {
    submitLoading.value = false
  }
}

async function handleDelete(row) {
  try {
    await ElMessageBox.confirm(`确定删除用户"${row.username}"吗?`, '删除确认', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await deleteUser(row.id)
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

<style scoped>
.avatar-uploader { display: inline-block; vertical-align: middle; margin-right: 12px; cursor: pointer; }
</style>
