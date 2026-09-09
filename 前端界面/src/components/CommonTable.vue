<template>
  <div class="common-table card-box">
    <el-table
      :data="tableData"
      v-loading="loading"
      border
      stripe
      style="width: 100%"
    >
      <!-- 序号列 -->
      <el-table-column v-if="showIndex" type="index" label="序号" width="60" align="center" />
      <!-- 动态列配置 -->
      <el-table-column
        v-for="col in columns"
        :key="col.prop"
        :prop="col.prop"
        :label="col.label"
        :width="col.width"
        :min-width="col.minWidth || 120"
        :align="col.align || 'left'"
        :show-overflow-tooltip="col.showOverflowTooltip !== false"
      >
        <template v-if="col.slot" #default="scope">
          <slot :name="col.slot" :row="scope.row" :index="scope.$index" />
        </template>
      </el-table-column>
      <!-- 操作栏(插槽) -->
      <el-table-column
        v-if="$slots.actions"
        label="操作"
        :width="actionWidth"
        :align="actionAlign"
        fixed="right"
      >
        <template #default="scope">
          <slot name="actions" :row="scope.row" :index="scope.$index" />
        </template>
      </el-table-column>
      <!-- 空数据 -->
      <template #empty>
        <el-empty description="暂无数据" />
      </template>
    </el-table>
    <!-- 分页 -->
    <div v-if="showPagination" class="pagination-wrap">
      <el-pagination
        v-model:current-page="pageNum"
        v-model:page-size="pageSizeVal"
        :page-sizes="pageSizes"
        :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        background
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  // 列配置 [{ prop, label, width, align, slot, minWidth, showOverflowTooltip }]
  columns: { type: Array, default: () => [] },
  tableData: { type: Array, default: () => [] },
  total: { type: Number, default: 0 },
  loading: { type: Boolean, default: false },
  // 是否显示序号列
  showIndex: { type: Boolean, default: true },
  // 操作列宽度
  actionWidth: { type: [Number, String], default: 180 },
  actionAlign: { type: String, default: 'center' },
  // 是否显示分页
  showPagination: { type: Boolean, default: true },
  // 当前页
  currentPage: { type: Number, default: 1 },
  // 每页条数
  pageSize: { type: Number, default: 10 },
  // 可选页大小
  pageSizes: { type: Array, default: () => [10, 20, 50, 100] }
})

const emit = defineEmits(['page-change', 'size-change', 'update:currentPage', 'update:pageSize'])

const pageNum = ref(props.currentPage)
watch(() => props.currentPage, (val) => { pageNum.value = val })

// pageSize 同样使用本地 ref, 不能直接 v-model 绑定 prop(prop 只读, 会编译报错)
const pageSizeVal = ref(props.pageSize)
watch(() => props.pageSize, (val) => { pageSizeVal.value = val })

function handlePageChange(page) {
  emit('update:currentPage', page)
  emit('page-change', page)
}
function handleSizeChange(size) {
  emit('update:pageSize', size)
  emit('size-change', size)
}
</script>

<style scoped>
.common-table { margin-top: 0; }
</style>
