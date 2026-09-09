import request from '@/utils/request'

// 图书相关 API

// 图书分页列表
export function getBookList(params) {
  return request.get('/book/list', { params })
}

// 图书详情
export function getBookDetail(id) {
  return request.get(`/book/${id}`)
}

// 新增图书
export function addBook(data) {
  return request.post('/book', data)
}

// 编辑图书
export function updateBook(id, data) {
  return request.put(`/book/${id}`, data)
}

// 删除图书
export function deleteBook(id) {
  return request.delete(`/book/${id}`)
}
