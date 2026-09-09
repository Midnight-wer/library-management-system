<template>
  <div class="search-bar card-box">
    <el-form :inline="true" :model="model" class="search-form">
      <!-- 搜索输入框 -->
      <el-form-item v-if="showKeyword" label="关键词">
        <el-input
          v-model="keyword"
          :placeholder="keywordPlaceholder"
          clearable
          style="width: 220px"
          @keyup.enter="handleSearch"
        />
      </el-form-item>
      <!-- 筛选下拉(自定义额外筛选项) -->
      <slot name="filters" />
      <el-form-item>
        <el-button type="primary" :icon="Search" @click="handleSearch">查询</el-button>
        <el-button :icon="Refresh" @click="handleReset">重置</el-button>
        <!-- 右侧操作插槽(如新增按钮) -->
        <span class="extra-actions">
          <slot name="actions" />
        </span>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup>
import { Search, Refresh } from '@element-plus/icons-vue'
import { ref, watch } from 'vue'

const props = defineProps({
  // 是否显示关键词输入
  showKeyword: { type: Boolean, default: true },
  keywordPlaceholder: { type: String, default: '请输入关键词搜索' },
  // 绑定的关键词初值
  modelValue: { type: String, default: '' }
})

const emit = defineEmits(['search', 'reset', 'update:modelValue'])

const keyword = ref(props.modelValue)

watch(() => props.modelValue, (val) => { keyword.value = val })
watch(keyword, (val) => emit('update:modelValue', val))

// 当前搜索栏的筛选模型 (供 slot 通过 v-model:filters 使用)
const model = ref({})

function handleSearch() {
  emit('search')
}
function handleReset() {
  keyword.value = ''
  emit('update:modelValue', '')
  emit('reset')
}
</script>

<style scoped>
.search-bar { margin-bottom: 16px; }
.search-form { display: flex; flex-wrap: wrap; align-items: center; }
.extra-actions { margin-left: 12px; }
</style>
