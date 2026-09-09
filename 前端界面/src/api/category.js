import request from '@/utils/request'

// 图书分类 API

// 获取全部分类
export function getCategoryList() {
  return request.get('/category/list')
}

// 新增分类
export function addCategory(data) {
  return request.post('/category', data)
}

// 编辑分类
export function updateCategory(id, data) {
  return request.put(`/category/${id}`, data)
}

// 删除分类
export function deleteCategory(id) {
  return request.delete(`/category/${id}`)
}
