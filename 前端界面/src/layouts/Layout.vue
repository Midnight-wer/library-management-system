<template>
  <el-container class="layout">
    <!-- 侧边栏 -->
    <el-aside :width="isCollapse ? '64px' : '220px'" class="aside">
      <div class="logo">
        <el-icon size="22" color="#fff"><Reading /></el-icon>
        <span v-if="!isCollapse" class="logo-text">图书管理系统</span>
      </div>
      <el-menu
        :default-active="activeMenu"
        :collapse="isCollapse"
        :collapse-transition="false"
        background-color="#001529"
        text-color="#ffffffd9"
        active-text-color="#ffffff"
        router
      >
        <el-menu-item index="/book/list">
          <el-icon><Menu /></el-icon>
          <span>图书列表</span>
        </el-menu-item>
        <el-menu-item index="/profile">
          <el-icon><User /></el-icon>
          <span>个人中心</span>
        </el-menu-item>
        <!-- 管理员菜单 -->
        <el-sub-menu v-if="userStore.isAdmin" index="admin">
          <template #title>
            <el-icon><Setting /></el-icon>
            <span>后台管理</span>
          </template>
          <el-menu-item index="/admin/dashboard">
            <el-icon><DataAnalysis /></el-icon>
            <span>后台首页</span>
          </el-menu-item>
          <el-menu-item index="/admin/books">
            <el-icon><Reading /></el-icon>
            <span>图书管理</span>
          </el-menu-item>
          <el-menu-item index="/admin/categories">
            <el-icon><Files /></el-icon>
            <span>分类管理</span>
          </el-menu-item>
          <el-menu-item index="/admin/borrows">
            <el-icon><Document /></el-icon>
            <span>借阅管理</span>
          </el-menu-item>
          <el-menu-item index="/admin/users">
            <el-icon><UserFilled /></el-icon>
            <span>用户管理</span>
          </el-menu-item>
        </el-sub-menu>
      </el-menu>
    </el-aside>

    <el-container>
      <!-- 顶部 -->
      <el-header class="header">
        <div class="header-left">
          <el-icon class="collapse-btn" size="20" @click="isCollapse = !isCollapse">
            <Fold v-if="!isCollapse" />
            <Expand v-else />
          </el-icon>
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item>{{ currentTitle }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="header-right">
          <el-dropdown @command="handleCommand">
            <span class="user-info">
              <el-avatar :size="32" :src="avatarUrl" class="avatar">
                <el-icon><User /></el-icon>
              </el-avatar>
              <span class="nickname">{{ userStore.nickname }}</span>
              <el-tag v-if="userStore.isAdmin" type="danger" size="small" effect="dark">管理员</el-tag>
              <el-tag v-else type="success" size="small" effect="plain">普通用户</el-tag>
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="profile">
                  <el-icon><User /></el-icon>个人中心
                </el-dropdown-item>
                <el-dropdown-item command="logout" divided>
                  <el-icon><SwitchButton /></el-icon>退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      <!-- 内容区 -->
      <el-main class="main">
        <router-view v-slot="{ Component }">
          <transition name="fade" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage, ElMessageBox } from 'element-plus'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const isCollapse = ref(false)

// 当前激活菜单
const activeMenu = computed(() => route.path)
// 当前页面标题
const currentTitle = computed(() => route.meta.title || '')

// 头像地址 (相对路径补全)
const avatarUrl = computed(() => {
  const a = userStore.userInfo && userStore.userInfo.avatar
  return a || ''
})

// 下拉菜单命令
function handleCommand(cmd) {
  if (cmd === 'profile') {
    router.push('/profile')
  } else if (cmd === 'logout') {
    ElMessageBox.confirm('确定要退出登录吗?', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning'
    }).then(() => {
      userStore.clearUser()
      ElMessage.success('已退出登录')
      router.push('/login')
    }).catch(() => {})
  }
}
</script>

<style scoped>
.layout { height: 100vh; }
.aside {
  background: #001529;
  transition: width 0.3s;
  overflow-x: hidden;
}
.logo {
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: #fff;
  background: #002140;
}
.logo-text { font-size: 16px; font-weight: 600; white-space: nowrap; }
.aside :deep(.el-menu) { border-right: none; }

.header {
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 1px 4px rgba(0, 21, 41, 0.08);
  padding: 0 16px;
}
.header-left { display: flex; align-items: center; gap: 16px; }
.collapse-btn { cursor: pointer; }
.header-right { display: flex; align-items: center; }
.user-info { display: flex; align-items: center; gap: 8px; cursor: pointer; }
.avatar { background: #409eff; }
.nickname { font-size: 14px; }

.main { background: #f0f2f5; padding: 16px; overflow-y: auto; }

.fade-enter-active, .fade-leave-active { transition: opacity 0.2s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
