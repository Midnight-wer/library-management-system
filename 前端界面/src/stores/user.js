import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

// 用户状态管理 (Pinia)
export const useUserStore = defineStore('user', () => {
  // token
  const token = ref(localStorage.getItem('library_token') || '')
  // 用户信息
  const userInfo = ref(JSON.parse(localStorage.getItem('library_user') || 'null'))

  // 是否登录
  const isLogin = computed(() => !!token.value)
  // 是否管理员
  const isAdmin = computed(() => userInfo.value && userInfo.value.role === 'admin')
  // 用户昵称(兜底账号)
  const nickname = computed(() => (userInfo.value ? userInfo.value.nickname || userInfo.value.username : ''))

  // 设置登录信息
  function setLogin(data) {
    token.value = data.token
    userInfo.value = data.userInfo
    localStorage.setItem('library_token', data.token)
    localStorage.setItem('library_user', JSON.stringify(data.userInfo))
  }

  // 更新用户信息(部分字段)
  function updateUserInfo(info) {
    userInfo.value = { ...userInfo.value, ...info }
    localStorage.setItem('library_user', JSON.stringify(userInfo.value))
  }

  // 清除用户信息
  function clearUser() {
    token.value = ''
    userInfo.value = null
    localStorage.removeItem('library_token')
    localStorage.removeItem('library_user')
  }

  return { token, userInfo, isLogin, isAdmin, nickname, setLogin, updateUserInfo, clearUser }
})
