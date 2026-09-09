<template>
  <el-dialog
    v-model="visible"
    :title="title"
    :width="width"
    :close-on-click-modal="false"
    @close="handleClose"
  >
    <el-form
      ref="formRef"
      :model="formModel"
      :rules="rules"
      label-width="100px"
    >
      <!-- 表单项插槽 -->
      <slot :form-model="formModel" />
    </el-form>
    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" :loading="submitLoading" @click="handleSubmit">确定</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, reactive, watch } from 'vue'
import { ElMessage } from 'element-plus'

const props = defineProps({
  // 是否显示(双向绑定)
  modelValue: { type: Boolean, default: false },
  // 标题
  title: { type: String, default: '表单' },
  // 弹窗宽度
  width: { type: String, default: '600px' },
  // 表单数据
  modelData: { type: Object, default: () => ({}) },
  // 校验规则
  rules: { type: Object, default: () => ({}) },
  // 提交loading
  submitLoading: { type: Boolean, default: false }
})

const emit = defineEmits(['update:modelValue', 'submit', 'reset'])

const visible = ref(props.modelValue)
const formRef = ref()
// 表单模型(深拷贝, 避免直接修改父组件数据)
const formModel = reactive({ ...props.modelData })

watch(() => props.modelValue, (val) => { visible.value = val })
watch(visible, (val) => emit('update:modelValue', val))

// 父组件数据变化时同步到表单模型
watch(() => props.modelData, (val) => {
  Object.keys(val).forEach((key) => {
    formModel[key] = val[key]
  })
}, { deep: true })

function handleClose() {
  formRef.value && formRef.value.resetFields()
  emit('update:modelValue', false)
  emit('reset')
}

function handleSubmit() {
  formRef.value.validate((valid) => {
    if (valid) {
      // 提交表单数据(深拷贝避免双向绑定污染)
      emit('submit', JSON.parse(JSON.stringify(formModel)))
    } else {
      ElMessage.warning('请完善表单必填项')
      return false
    }
  })
}

// 暴露重置方法
defineExpose({
  resetFields: () => formRef.value && formRef.value.resetFields()
})
</script>

<style scoped>
:deep(.el-dialog__body) { padding: 16px 24px; }
</style>
