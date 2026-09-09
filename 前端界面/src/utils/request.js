import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import router from '@/router'

// 创建 axios 实例
const service = axios.create({
  baseURL: '/api',
  timeout: 30000
})

// 请求拦截器: 自动带上 token
service.interceptors.request.use(
  (config) => {
    const userStore = useUserStore()
    if (userStore.token) {
      config.headers['Authorization'] = 'Bearer ' + userStore.token
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// 读取 blob 响应中的 JSON 错误体(导出文件失败时后端返回的是 JSON 而非文件流)
function readBlobError(blob) {
  return new Promise((resolve) => {
    const reader = new FileReader()
    reader.onload = () => {
      try {
        resolve(JSON.parse(reader.result))
      } catch {
        resolve(null)
      }
    }
    reader.onerror = () => resolve(null)
    reader.readAsText(blob)
  })
}

// 响应拦截器: 统一错误处理
service.interceptors.response.use(
  async (response) => {
    // 文件流(导出Excel): 正常二进制直接返回; 若后端返回 JSON 错误体则拦截提示
    if (response.config.responseType === 'blob') {
      // 后端 JSON 响应的 Content-Type 可能带 charset 参数, 用 includes 兼容
      if (response.data && (response.data.type || '').includes('application/json')) {
        const errBody = await readBlobError(response.data)
        const msg = errBody?.message || '导出失败'
        if (errBody?.code === 401) {
          ElMessage.error('登录已失效,请重新登录')
          const userStore = useUserStore()
          userStore.clearUser()
          router.push('/login')
        } else {
          ElMessage.error(msg)
        }
        return Promise.reject(new Error(msg))
      }
      return response
    }
    const res = response.data
    // 统一返回结构: { code, message, data }
    if (res.code === 200) {
      return res
    }
    // 401 未登录 / token失效
    if (res.code === 401) {
      ElMessage.error(res.message || '登录已失效,请重新登录')
      const userStore = useUserStore()
      userStore.clearUser()
      router.push('/login')
      return Promise.reject(new Error(res.message || 'Unauthorized'))
    }
    // 403 权限不足
    if (res.code === 403) {
      ElMessage.error(res.message || '权限不足')
      return Promise.reject(new Error(res.message || 'Forbidden'))
    }
    // 其他业务异常
    ElMessage.error(res.message || '请求失败')
    return Promise.reject(new Error(res.message || 'Error'))
  },
  (error) => {
    // HTTP 层错误
    let message = error.message
    if (error.response) {
      const status = error.response.status
      if (status === 401) {
        message = '登录已失效,请重新登录'
        const userStore = useUserStore()
        userStore.clearUser()
        router.push('/login')
      } else if (status === 403) {
        message = '权限不足'
      } else if (status === 500) {
        message = '服务器异常'
      }
    } else if (error.message.includes('timeout')) {
      message = '请求超时'
    }
    ElMessage.error(message)
    return Promise.reject(error)
  }
)

export default service
