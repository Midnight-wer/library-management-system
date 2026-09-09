<template>
  <div class="dashboard-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :xs="12" :sm="6">
        <div class="stat-card stat-books">
          <div class="stat-icon"><el-icon size="32"><Reading /></el-icon></div>
          <div class="stat-info">
            <p class="stat-label">总图书</p>
            <p class="stat-value">{{ stats.totalBooks || 0 }}</p>
          </div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="6">
        <div class="stat-card stat-users">
          <div class="stat-icon"><el-icon size="32"><UserFilled /></el-icon></div>
          <div class="stat-info">
            <p class="stat-label">总用户</p>
            <p class="stat-value">{{ stats.totalUsers || 0 }}</p>
          </div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="6">
        <div class="stat-card stat-borrowing">
          <div class="stat-icon"><el-icon size="32"><Document /></el-icon></div>
          <div class="stat-info">
            <p class="stat-label">在借数量</p>
            <p class="stat-value">{{ stats.borrowingCount || 0 }}</p>
          </div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="6">
        <div class="stat-card stat-total">
          <div class="stat-icon"><el-icon size="32"><DataAnalysis /></el-icon></div>
          <div class="stat-info">
            <p class="stat-label">累计借阅</p>
            <p class="stat-value">{{ stats.totalBorrowCount || 0 }}</p>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表 -->
    <el-row :gutter="16">
      <el-col :xs="24" :md="10">
        <div class="card-box chart-box">
          <h3 class="chart-title">分类图书数量</h3>
          <div ref="pieRef" class="chart"></div>
        </div>
      </el-col>
      <el-col :xs="24" :md="14">
        <div class="card-box chart-box">
          <h3 class="chart-title">近7天借阅趋势</h3>
          <div ref="lineRef" class="chart"></div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, nextTick } from 'vue'
// echarts 按需引入: 只注册本页用到的饼图/折线图及必要组件, 避免全量打包(~1MB)
import * as echarts from 'echarts/core'
import { PieChart, LineChart } from 'echarts/charts'
import { TooltipComponent, LegendComponent, GridComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import { getHomeStatistics } from '@/api/statistics'

echarts.use([PieChart, LineChart, TooltipComponent, LegendComponent, GridComponent, CanvasRenderer])

const stats = ref({})
const pieRef = ref()
const lineRef = ref()
let pieChart = null
let lineChart = null

async function loadData() {
  const res = await getHomeStatistics()
  stats.value = res.data
  await nextTick()
  renderPie()
  renderLine()
}

function renderPie() {
  if (!pieRef.value) return
  if (!pieChart) pieChart = echarts.init(pieRef.value)
  const data = stats.value.categoryBookCount || []
  pieChart.setOption({
    tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
    legend: { bottom: 0, type: 'scroll' },
    series: [
      {
        name: '图书数量',
        type: 'pie',
        radius: ['40%', '65%'],
        center: ['50%', '45%'],
        avoidLabelOverlap: true,
        itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
        label: { show: false },
        emphasis: { label: { show: true, fontSize: 16, fontWeight: 'bold' } },
        data
      }
    ]
  })
}

function renderLine() {
  if (!lineRef.value) return
  if (!lineChart) lineChart = echarts.init(lineRef.value)
  const trend = stats.value.borrowTrend || { dates: [], counts: [] }
  lineChart.setOption({
    tooltip: { trigger: 'axis' },
    grid: { left: 40, right: 20, top: 30, bottom: 40 },
    xAxis: { type: 'category', data: trend.dates, axisLabel: { rotate: 0 } },
    yAxis: { type: 'value', minInterval: 1 },
    series: [
      {
        name: '借阅次数',
        type: 'line',
        smooth: true,
        data: trend.counts,
        areaStyle: { color: 'rgba(64, 158, 255, 0.3)' },
        lineStyle: { color: '#409eff', width: 3 },
        itemStyle: { color: '#409eff' },
        symbol: 'circle',
        symbolSize: 8
      }
    ]
  })
}

function handleResize() {
  pieChart && pieChart.resize()
  lineChart && lineChart.resize()
}

onMounted(() => {
  loadData()
  window.addEventListener('resize', handleResize)
})

onBeforeUnmount(() => {
  window.removeEventListener('resize', handleResize)
  pieChart && pieChart.dispose()
  lineChart && lineChart.dispose()
})
</script>

<style scoped>
.stat-row { margin-bottom: 16px; }
.stat-card {
  background: #fff;
  border-radius: 8px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 0 1px 4px rgba(0, 21, 41, 0.08);
  transition: transform 0.2s;
}
.stat-card:hover { transform: translateY(-4px); }
.stat-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
}
.stat-books .stat-icon { background: linear-gradient(135deg, #667eea, #764ba2); }
.stat-users .stat-icon { background: linear-gradient(135deg, #43cea2, #185a9d); }
.stat-borrowing .stat-icon { background: linear-gradient(135deg, #fa709a, #fee140); }
.stat-total .stat-icon { background: linear-gradient(135deg, #4facfe, #00f2fe); }
.stat-label { font-size: 14px; color: #909399; margin: 0 0 4px; }
.stat-value { font-size: 28px; font-weight: 600; color: #303133; margin: 0; }
.chart-box { margin-bottom: 16px; }
.chart-title { font-size: 16px; margin: 0 0 16px; color: #303133; }
.chart { height: 340px; width: 100%; }
</style>
