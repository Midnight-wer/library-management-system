import { createApp } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'
// 仅注册模板中全局使用的图标(各页面按需在本组件内 import 其余图标), 避免全量打包
// Fold/Expand 为 el-menu 折叠按钮内部按全局组件名解析的图标, 必须全局注册
import {
  Reading,
  Menu,
  User,
  Setting,
  DataAnalysis,
  Files,
  Document,
  UserFilled,
  ArrowDown,
  SwitchButton,
  Fold,
  Expand
} from '@element-plus/icons-vue'

import App from './App.vue'
import router from './router'
import './styles/global.css'

// 创建 Vue 应用
const app = createApp(App)

// 注册全局 Element Plus 图标(仅布局/首页等未局部引入的公共图标)
const globalIcons = {
  Reading,
  Menu,
  User,
  Setting,
  DataAnalysis,
  Files,
  Document,
  UserFilled,
  ArrowDown,
  SwitchButton,
  Fold,
  Expand
}
for (const [key, component] of Object.entries(globalIcons)) {
  app.component(key, component)
}

app.use(createPinia())
app.use(router)
app.use(ElementPlus, { locale: zhCn })

app.mount('#app')
