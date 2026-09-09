<template>
  <div class="borrow-manage-page">
    <!-- 搜索栏 -->
    <SearchBar v-model="keyword" keyword-placeholder="图书名称" @search="loadList" @reset="handleReset">
      <template #filters>
        <el-select v-model="status" placeholder="状态" clearable style="width: 140px" @change="loadList">
          <el-option label="待审核" value="待审核" />
          <el-option label="借阅中" value="借阅中" />
          <el-option label="已归还" value="已归还" />
          <el-option label="驳回" value="驳回" />
        </el-select>
      </template>
      <template #actions>
        <el-button type="success" :icon="Download" @click="handleExport">导出Excel</el-button>
      </template>
    </SearchBar>

    <!-- 表格 -->
    <CommonTable
      :columns="columns"
      :table-data="list"
      :total="total"
      :loading="loading"
      v-model:current-page="pageNum"
      v-model:page-size="pageSize"
      :action-width="240"
      @page-change="loadList"
      @size-change="loadList"
    >
      <template #statusSlot="{ row }">
        <StatusTag :status="row.status" />
      </template>
      <template #actions="{ row }">
        <template v-if="row.status === '待审核'">
          <el-button link type="success" :icon="Check" @click="handleAudit(row, 'pass')">通过</el-button>
          <el-button link type="danger" :icon="Close" @click="openReject(row)">驳回</el-button>
        </template>
        <el-button v-if="row.status === '借阅中'" link type="primary" :icon="Finished" @click="handleReturn(row)">确认归还</el-button>
        <el-button link type="info" :icon="View" @click="openDetail(row)">详情</el-button>
      </template>
    </CommonTable>

    <!-- 驳回弹窗 -->
    <el-dialog v-model="rejectVisible" title="驳回借阅申请" width="480px">
      <el-form ref="rejectFormRef" :model="rejectForm" :rules="rejectRules" label-width="100px">
        <el-form-item label="图书">
          <span>{{ currentRow && currentRow.bookName }}</span>
        </el-form-item>
        <el-form-item label="借阅人">
          <span>{{ currentRow && currentRow.nickname }} ({{ currentRow && currentRow.username }})</span>
        </el-form-item>
        <el-form-item label="驳回备注" prop="remark">
          <el-input v-model="rejectForm.remark" type="textarea" :rows="3" placeholder="请填写驳回原因" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="rejectVisible = false">取消</el-button>
        <el-button type="danger" :loading="auditLoading" @click="confirmReject">确认驳回</el-button>
      </template>
    </el-dialog>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailVisible" title="借阅详情" width="560px">
      <el-descriptions v-if="currentRow" :column="2" border>
        <el-descriptions-item label="记录ID">{{ currentRow.id }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <StatusTag :status="currentRow.status" />
        </el-descriptions-item>
        <el-descriptions-item label="图书名称">{{ currentRow.bookName }}</el-descriptions-item>
        <el-descriptions-item label="作者">{{ currentRow.author || '-' }}</el-descriptions-item>
        <el-descriptions-item label="借阅人">{{ currentRow.nickname }}</el-descriptions-item>
        <el-descriptions-item label="账号">{{ currentRow.username }}</el-descriptions-item>
        <el-descriptions-item label="借阅时间">{{ currentRow.borrowTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="归还时间">{{ currentRow.returnTime || '-' }}</el-descriptions-item>
        <el-descriptions-item label="申请时间">{{ currentRow.createTime }}</el-descriptions-item>
        <el-descriptions-item label="驳回备注">{{ currentRow.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Download, Check, Close, Finished, View } from '@element-plus/icons-vue'
import SearchBar from '@/components/SearchBar.vue'
import CommonTable from '@/components/CommonTable.vue'
import StatusTag from '@/components/StatusTag.vue'
import { getBorrowList, auditBorrow, returnBorrow, exportBorrow } from '@/api/borrow'

const keyword = ref('')
const status = ref('')
const pageNum = ref(1)
const pageSize = ref(10)
const total = ref(0)
const list = ref([])
const loading = ref(false)

const columns = [
  { prop: 'id', label: '记录ID', width: 80, align: 'center' },
  { prop: 'username', label: '账号', width: 120 },
  { prop: 'nickname', label: '昵称', width: 110 },
  { prop: 'bookName', label: '图书名称', minWidth: 160 },
  { prop: 'author', label: '作者', width: 110 },
  { prop: 'status', label: '状态', width: 100, slot: 'statusSlot', align: 'center' },
  { prop: 'borrowTime', label: '借阅时间', width: 160 },
  { prop: 'returnTime', label: '归还时间', width: 160 },
  { prop: 'remark', label: '备注', minWidth: 140 }
]

// 驳回
const rejectVisible = ref(false)
const rejectFormRef = ref()
const auditLoading = ref(false)
const currentRow = ref(null)
const rejectForm = reactive({ remark: '' })
const rejectRules = {
  remark: [{ required: true, message: '请填写驳回备注', trigger: 'blur' }]
}

// 详情
const detailVisible = ref(false)

async function loadList() {
  loading.value = true
  try {
    const res = await getBorrowList({
      pageNum: pageNum.value,
      pageSize: pageSize.value,
      status: status.value || undefined,
      keyword: keyword.value || undefined
    })
    list.value = res.data.records
    total.value = Number(res.data.total)
  } finally {
    loading.value = false
  }
}

function handleReset() {
  keyword.value = ''
  status.value = ''
  pageNum.value = 1
  loadList()
}

// 审核-通过
async function handleAudit(row, action) {
  try {
    await ElMessageBox.confirm(`确定通过"${row.nickname}"借阅《${row.bookName}》的申请吗?`, '审核确认', {
      confirmButtonText: '确定通过',
      cancelButtonText: '取消',
      type: 'success'
    })
    await auditBorrow(row.id, { action: 'pass' })
    ElMessage.success('已通过审核')
    loadList()
  } catch (e) {
    if (e !== 'cancel') {
      // 错误已在拦截器提示
    }
  }
}

// 打开驳回弹窗
function openReject(row) {
  currentRow.value = row
  rejectForm.remark = ''
  rejectVisible.value = true
}

// 确认驳回
async function confirmReject() {
  await rejectFormRef.value.validate(async (valid) => {
    if (!valid) return
    auditLoading.value = true
    try {
      await auditBorrow(currentRow.value.id, { action: 'reject', remark: rejectForm.remark })
      ElMessage.success('已驳回')
      rejectVisible.value = false
      loadList()
    } finally {
      auditLoading.value = false
    }
  })
}

// 确认归还
async function handleReturn(row) {
  try {
    await ElMessageBox.confirm(`确定《${row.bookName}》已归还吗?`, '归还确认', {
      confirmButtonText: '确认归还',
      cancelButtonText: '取消',
      type: 'warning'
    })
    await returnBorrow(row.id)
    ElMessage.success('归还成功')
    loadList()
  } catch (e) {
    if (e !== 'cancel') {
      // 错误已在拦截器提示
    }
  }
}

// 详情
function openDetail(row) {
  currentRow.value = row
  detailVisible.value = true
}

// 导出 Excel
async function handleExport() {
  try {
    const res = await exportBorrow({
      status: status.value || undefined,
      keyword: keyword.value || undefined
    })
    // 处理文件流下载
    const blob = new Blob([res.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
    const fileName = decodeURIComponent(res.headers['content-disposition'].split('filename=')[1] || `借阅记录_${Date.now()}.xlsx`)
    const url = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = url
    link.download = fileName
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
    window.URL.revokeObjectURL(url)
    ElMessage.success('导出成功')
  } catch (e) {
    // 错误已在拦截器提示
  }
}

onMounted(() => {
  loadList()
})
</script>
