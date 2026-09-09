import request from '@/utils/request'

// 数据统计 API

// 后台首页统计数据
export function getHomeStatistics() {
  return request.get('/statistics/home')
}
