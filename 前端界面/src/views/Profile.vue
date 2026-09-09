<template>
  <div class="profile-page">
    <el-tabs v-model="activeTab" class="card-box tabs-box">
      <!-- 个人资料 -->
      <el-tab-pane label="个人资料" name="profile">
        <el-form :model="profileForm" label-width="100px" style="max-width: 520px" v-loading="loading">
          <el-form-item label="头像">
            <el-upload
              class="avatar-uploader"
              :show-file-list="false"
              :http-request="handleAvatarUpload"
              accept="image/*"
            >
              <el-avatar :size="100" :src="avatarUrl">
                <el-icon size="40"><User /></el-icon>
              </el-avatar>
              <div class="avatar-tip">点击上传</div>
            </el-upload>
          </el-form-item>
          <el-form-item label="账号">
            <el-input :model-value="userInfo.username" disabled />
          </el-form-item>
          <el-form-item label="角色">
            <el-tag :type="userInfo.role === 'admin' ? 'danger' : 'success'">
              {{ userInfo.role === 'admin' ? '管理员' : '普通用户' }}
            </el-tag>
          </el-form-item>
          <el-form-item label="昵称">
            <el-input v-model="profileForm.nickname" placeholder="请输入昵称" />
          </el-form-item>
          <el-form-item label="手机号">
            <el-input v-model="profileForm.phone" placeholder="请输入手机号" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="saveLoading" @click="saveProfile">保存修改</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- 修改密码 -->
      <el-tab-pane label="修改密码" name="password">
        <el-form ref="pwdFormRef" :model="pwdForm" :rules="pwdRules" label-width="100px" style="max-width: 520px">
          <el-form-item label="原密码" prop="oldPassword">
            <el-input v-model="pwdForm.oldPassword" type="password" show-password placeholder="请输入原密码" />
          </el-form-item>
          <el-form-item label="新密码" prop="newPassword">
            <el-input v-model="pwdForm.newPassword" type="password" show-password placeholder="请输入新密码(6-20位)" />
          </el-form-item>
          <el-form-item label="确认密码" prop="confirmPassword">
            <el-input v-model="pwdForm.confirmPassword" type="password" show-password placeholder="请再次输入新密码" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" :loading="pwdLoading" @click="savePassword">修改密码</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- 我的借阅 -->
      <el-tab-pane label="我的借阅" name="borrow">
        <div class="toolbar">
          <div class="left">
            <el-input v-model="borrowKeyword" placeholder="图书名称" clearable style="width: 200px" @keyup.enter="loadBorrows" />
            <el-select v-model="borrowStatus" placeholder="状态" clearable style="width: 140px" @change="loadBorrows">
              <el-option label="待审核" value="待审核" />
              <el-option label="借阅中" value="借阅中" />
              <el-option label="已归还" value="已归还" />
              <el-option label="驳回" value="驳回" />
            </el-select>
            <el-button type="primary" :icon="Search" @click="loadBorrows">查询</el-button>
            <el-button :icon="Refresh" @click="resetBorrowQuery">重置</el-button>
          </div>
        </div>
        <CommonTable
          :columns="borrowColumns"
          :table-data="borrowList"
          :total="borrowTotal"
          :loading="borrowLoading"
          v-model:current-page="borrowPageNum"
          v-model:page-size="borrowPageSize"
          :action-width="120"
          @page-change="loadBorrows"
          @size-change="loadBorrows"
        >
          <template #statusSlot="{ row }">
            <StatusTag :status="row.status" />
          </template>
          <template #actions="{ row }">
            <el-button link type="primary" @click="$router.push(`/book/${row.bookId}`)">查看图书</el-button>
          </template>
        </CommonTable>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { User, Search, Refresh } from '@element-plus/icons-vue'
import CommonTable from '@/components/CommonTable.vue'
import StatusTag from '@/components/StatusTag.vue'
import { getUserInfo, updateProfile, updatePassword } from '@/api/user'
import { getMyBorrowList } from '@/api/borrow'
import { uploadFile } from '@/api/file'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()

const activeTab = ref('profile')
const loading = ref(false)
const saveLoading = ref(false)

const userInfo = reactive({ username: '', role: 'user', nickname: '', phone: '', avatar: '' })
const profileForm = reactive({ nickname: '', phone: '', avatar: '' })

const avatarUrl = computed(() => userInfo.avatar || '')

// 加载用户信息
async function loadUserInfo() {
  loading.value = true
  try {
    const res = await getUserInfo()
    Object.assign(userInfo, res.data)
    profileForm.nickname = res.data.nickname
    profileForm.phone = res.data.phone
    profileForm.avatar = res.data.avatar
    // 同步到 store
    userStore.updateUserInfo(res.data)
  } finally {
    loading.value = false
  }
}

// 上传头像
async function handleAvatarUpload({ file }) {
  try {
    const res = await uploadFile(file)
    profileForm.avatar = res.data.url
    userInfo.avatar = res.data.url
    // 同步到 store
    userStore.updateUserInfo({ avatar: res.data.url })
    ElMessage.success('头像上传成功,请点击保存修改')
  } catch (e) {
    // 错误已在拦截器提示
  }
}

// 保存个人资料
async function saveProfile() {
  saveLoading.value = true
  try {
    await updateProfile(profileForm)
    ElMessage.success('保存成功')
    userStore.updateUserInfo(profileForm)
  } finally {
    saveLoading.value = false
  }
}

// 修改密码
const pwdFormRef = ref()
const pwdLoading = ref(false)
const pwdForm = reactive({ oldPassword: '', newPassword: '', confirmPassword: '' })
const pwdRules = {
  oldPassword: [{ required: true, message: '请输入原密码', trigger: 'blur' }],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度需在6~20之间', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请再次输入新密码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== pwdForm.newPassword) callback(new Error('两次输入的密码不一致'))
        else callback()
      },
      trigger: 'blur'
    }
  ]
}
async function savePassword() {
  await pwdFormRef.value.validate(async (valid) => {
    if (!valid) return
    pwdLoading.value = true
    try {
      await updatePassword({ oldPassword: pwdForm.oldPassword, newPassword: pwdForm.newPassword })
      ElMessage.success('密码修改成功,请重新登录')
      userStore.clearUser()
      setTimeout(() => { location.href = '/login' }, 1500)
    } finally {
      pwdLoading.value = false
    }
  })
}

// 我的借阅记录
const borrowKeyword = ref('')
const borrowStatus = ref('')
const borrowPageNum = ref(1)
const borrowPageSize = ref(10)
const borrowTotal = ref(0)
const borrowList = ref([])
const borrowLoading = ref(false)
const borrowColumns = [
  { prop: 'bookName', label: '图书名称', minWidth: 160 },
  { prop: 'author', label: '作者', width: 120 },
  { prop: 'status', label: '状态', width: 100, slot: 'statusSlot', align: 'center' },
  { prop: 'borrowTime', label: '借阅时间', width: 160 },
  { prop: 'returnTime', label: '归还时间', width: 160 },
  { prop: 'remark', label: '备注', minWidth: 140 },
  { prop: 'createTime', label: '申请时间', width: 160 }
]

async function loadBorrows() {
  borrowLoading.value = true
  try {
    const res = await getMyBorrowList({
      pageNum: borrowPageNum.value,
      pageSize: borrowPageSize.value,
      status: borrowStatus.value || undefined,
      keyword: borrowKeyword.value || undefined
    })
    borrowList.value = res.data.records
    borrowTotal.value = Number(res.data.total)
  } finally {
    borrowLoading.value = false
  }
}
function resetBorrowQuery() {
  borrowKeyword.value = ''
  borrowStatus.value = ''
  borrowPageNum.value = 1
  loadBorrows()
}

onMounted(() => {
  loadUserInfo()
  loadBorrows()
})
</script>

<style scoped>
.tabs-box { padding: 16px; }
.avatar-uploader {
  display: inline-block;
  position: relative;
  cursor: pointer;
}
.avatar-tip {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  text-align: center;
  font-size: 12px;
  color: #fff;
  background: rgba(0, 0, 0, 0.5);
  border-radius: 0 0 50px 50px;
  height: 24px;
  line-height: 24px;
}
</style>
