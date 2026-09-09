import request from '@/utils/request'

// 用户相关 API

// 注册
export function register(data) {
  return request.post('/user/register', data)
}

// 登录
export function login(data) {
  return request.post('/user/login', data)
}

// 获取当前登录用户信息
export function getUserInfo() {
  return request.get('/user/info')
}

// 修改个人资料
export function updateProfile(data) {
  return request.put('/user/info', data)
}

// 修改密码
export function updatePassword(data) {
  return request.put('/user/password', data)
}

// 用户分页列表 (admin)
export function getUserList(params) {
  return request.get('/user/list', { params })
}

// 编辑用户 (admin)
export function updateUser(id, data) {
  return request.put(`/user/${id}`, data)
}

// 删除用户 (admin)
export function deleteUser(id) {
  return request.delete(`/user/${id}`)
}
