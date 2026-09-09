<template>
  <div class="login-page">
    <div class="login-box">
      <div class="login-left">
        <div class="brand">
          <el-icon size="48"><Reading /></el-icon>
          <h1>图书管理系统</h1>
          <p>校园图书借阅一站式管理平台</p>
        </div>
      </div>
      <div class="login-right">
        <h2 class="title">用户登录</h2>
        <el-form ref="formRef" :model="form" :rules="rules" size="large">
          <el-form-item prop="username">
            <el-input v-model="form.username" placeholder="请输入账号" :prefix-icon="User" />
          </el-form-item>
          <el-form-item prop="password">
            <el-input v-model="form.password" type="password" show-password placeholder="请输入密码" :prefix-icon="Lock" @keyup.enter="handleLogin" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" class="login-btn" :loading="loading" @click="handleLogin">登 录</el-button>
          </el-form-item>
          <div class="tips">
            <span>还没有账号?</span>
            <router-link to="/register" class="link">立即注册</router-link>
          </div>
          <div class="demo-account">
            <p>测试账号:</p>
            <p>管理员 admin / 123456</p>
            <p>普通用户 zhangsan / 123456</p>
          </div>
        </el-form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { User, Lock } from '@element-plus/icons-vue'
import { login } from '@/api/user'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()

const formRef = ref()
const loading = ref(false)

const form = reactive({
  username: '',
  password: ''
})

const rules = {
  username: [{ required: true, message: '请输入账号', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

async function handleLogin() {
  await formRef.value.validate(async (valid) => {
    if (!valid) return
    loading.value = true
    try {
      const res = await login(form)
      userStore.setLogin(res.data)
      ElMessage.success('登录成功')
      router.push('/')
    } finally {
      loading.value = false
    }
  })
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}
.login-box {
  display: flex;
  width: 100%;
  max-width: 880px;
  height: 520px;
  background: #fff;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.2);
}
/* 窄屏/移动端: 隐藏左侧品牌区, 表单区自适应 */
@media (max-width: 768px) {
  .login-box { height: auto; flex-direction: column; }
  .login-left { display: none; }
  .login-right { padding: 32px 24px; }
}
.login-left {
  width: 44%;
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  text-align: center;
}
.brand h1 { font-size: 26px; margin: 16px 0 8px; }
.brand p { font-size: 14px; opacity: 0.9; }
.login-right {
  flex: 1;
  padding: 48px 40px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}
.title { text-align: center; margin-bottom: 32px; color: #303133; }
.login-btn { width: 100%; }
.tips { text-align: center; margin-top: 12px; font-size: 14px; color: #606266; }
.link { color: #409eff; margin-left: 4px; }
.demo-account {
  margin-top: 24px;
  padding: 12px;
  background: #f5f7fa;
  border-radius: 6px;
  font-size: 12px;
  color: #909399;
  line-height: 1.8;
}
.demo-account p { margin: 0; }
</style>
