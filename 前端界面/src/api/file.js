import request from '@/utils/request'

// 文件上传 API

// 上传文件 (头像、图书封面)
export function uploadFile(file) {
  const formData = new FormData()
  formData.append('file', file)
  return request.post('/file/upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  })
}
