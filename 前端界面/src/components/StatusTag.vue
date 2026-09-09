<template>
  <el-tag :type="tagType" :effect="effect" round>{{ statusText }}</el-tag>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  // 借阅状态
  status: { type: String, default: '' },
  // 标签风格 light / dark / plain
  effect: { type: String, default: 'light' }
})

// 状态映射: 文本 + 颜色
const statusMap = {
  '待审核': { type: 'warning', text: '待审核' },
  '借阅中': { type: 'primary', text: '借阅中' },
  '已归还': { type: 'success', text: '已归还' },
  '驳回': { type: 'danger', text: '驳回' }
}

const tagType = computed(() => (statusMap[props.status] ? statusMap[props.status].type : 'info'))
const statusText = computed(() => (statusMap[props.status] ? statusMap[props.status].text : props.status))
</script>
