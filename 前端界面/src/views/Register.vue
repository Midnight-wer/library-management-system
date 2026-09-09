<template>
  <div class="register-page">
    <div class="register-box">
      <h2 class="title">用户注册</h2>
      <el-form ref="formRef" :model="form" :rules="rules" size="large" label-width="80px">
        <el-form-item label="账号" prop="username">
          <el-input v-model="form.username" placeholder="3-50位账号" :prefix-icon="User" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" type="password" show-password placeholder="6-20位密码" :prefix-icon="Lock" />
        </el-form-item>
        <el-form-item label="昵称" prop="nickname">
          <el-input v-model="form.nickname" placeholder="请输入昵称(选填)" />
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="请输入手机号(选填)" :prefix-icon="Iphone" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" class="register-btn" :loading="loading" @click="handleRegister">注 册</el-button>
        </el-form-item>
        <div class="tips">
          <span>已有账号?</span>
          <router-link to="/login" class="link">去登录</router-link>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock, Iphone } from '@element-plus/icons-vue'
import { register } from '@/api/user'

const router = useRouter()
const formRef = ref()
const loading = ref(false)

const form = reactive({
  username: '',
  password: '',
  nickname: '',
  phone: ''
})

const rules = {
  username: [
    { required: true, message: '请输入账号', trigger: 'blur' },
    { min: 3, max: 50, message: '账号长度需在3~50之间', trigger: 'blur' }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, max: 20, message: '密码长度需在6~20之间', trigger: 'blur' }
  ],
  nickname: [{ max: 50, message: '昵称长度不能超过50', trigger: 'blur' }],
  phone: [{ max: 20, message: '手机号长度不正确', trigger: 'blur' }]
}

async function handleRegister() {
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    loading.value = true
    try {
      await register(form)
      ElMessage.success('注册成功,请登录')
      router.push('/login')
    } finally {
      loading.value = false
    }
  })
}
</script>

<style scoped>
.register-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: linear-gradient(135deg, #43cea2 0%, #185a9d 100%);
}
.register-box {
  width: 100%;
  max-width: 460px;
  background: #fff;
  border-radius: 12px;
  padding: 40px;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2);
}
/* 窄屏/移动端: 缩小内边距避免内容溢出 */
@media (max-width: 480px) {
  .register-box { padding: 28px 20px; }
}
.title { text-align: center; margin-bottom: 32px; color: #303133; }
.register-btn { width: 100%; }
.tips { text-align: center; margin-top: 12px; font-size: 14px; color: #606266; }
.link { color: #409eff; margin-left: 4px; }
</style>
