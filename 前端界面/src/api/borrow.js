import request from '@/utils/request'

// 借阅 API

// 提交借阅申请
export function submitBorrow(data) {
  return request.post('/borrow', data)
}

// 我的借阅记录分页
export function getMyBorrowList(params) {
  return request.get('/borrow/my', { params })
}

// 全部借阅记录分页 (admin)
export function getBorrowList(params) {
  return request.get('/borrow/list', { params })
}

// 借阅审核
export function auditBorrow(id, data) {
  return request.put(`/borrow/${id}/audit`, data)
}

// 确认归还
export function returnBorrow(id) {
  return request.put(`/borrow/${id}/return`)
}

// 导出借阅 Excel (admin)
export function exportBorrow(params) {
  return request.get('/borrow/export', {
    params,
    responseType: 'blob'
  })
}
