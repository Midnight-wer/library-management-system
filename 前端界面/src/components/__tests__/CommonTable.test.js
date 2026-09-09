import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ElementPlus from 'element-plus'
import CommonTable from '../CommonTable.vue'

// BUG-01 回归: 分页组件 page-size 直接 v-model 绑定 prop 会导致编译失败(页面白屏+构建失败),
// 必须使用本地 ref 中转并正确发出 update:pageSize / size-change 事件
function mountTable(props = {}) {
  return mount(CommonTable, {
    props: {
      columns: [{ prop: 'bookName', label: '书名' }],
      tableData: [{ bookName: 'Java核心技术' }],
      total: 100,
      ...props
    },
    global: {
      plugins: [ElementPlus]
    }
  })
}

describe('CommonTable 分页组件 (BUG-01)', () => {
  it('组件能正常挂载, 表格与列配置被正确渲染', () => {
    const wrapper = mountTable()
    expect(wrapper.find('.common-table').exists()).toBe(true)
    expect(wrapper.findComponent({ name: 'ElTable' }).exists()).toBe(true)
    // 1 个数据列 + 1 个序号列(showIndex 默认开启)
    const columns = wrapper.findAllComponents({ name: 'ElTableColumn' })
    expect(columns.length).toBe(2)
  })

  it('每页条数变化时发出 update:pageSize 和 size-change 事件', async () => {
    const wrapper = mountTable({ pageSize: 10 })
    const pagination = wrapper.findComponent({ name: 'ElPagination' })
    expect(pagination.exists()).toBe(true)

    // 模拟用户在分页器上把每页条数从 10 切换为 20
    pagination.vm.$emit('size-change', 20)
    await wrapper.vm.$nextTick()

    expect(wrapper.emitted('update:pageSize')).toBeTruthy()
    expect(wrapper.emitted('update:pageSize')[0]).toEqual([20])
    expect(wrapper.emitted('size-change')[0]).toEqual([20])
  })

  it('页码变化时发出 update:currentPage 和 page-change 事件', async () => {
    const wrapper = mountTable({ currentPage: 1 })
    const pagination = wrapper.findComponent({ name: 'ElPagination' })

    pagination.vm.$emit('current-change', 3)
    await wrapper.vm.$nextTick()

    expect(wrapper.emitted('update:currentPage')[0]).toEqual([3])
    expect(wrapper.emitted('page-change')[0]).toEqual([3])
  })

  it('外部 pageSize prop 更新后同步到分页组件', async () => {
    const wrapper = mountTable({ pageSize: 10 })
    const pagination = wrapper.findComponent({ name: 'ElPagination' })
    expect(pagination.props('pageSize')).toBe(10)

    await wrapper.setProps({ pageSize: 20 })
    expect(pagination.props('pageSize')).toBe(20)
  })
})
