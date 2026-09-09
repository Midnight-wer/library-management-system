import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { ElMessage } from 'element-plus'

// 路由表
const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { title: '登录', public: true }
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/Register.vue'),
    meta: { title: '注册', public: true }
  },
  {
    path: '/',
    component: () => import('@/layouts/Layout.vue'),
    redirect: '/book/list',
    children: [
      {
        path: 'book/list',
        name: 'BookList',
        component: () => import('@/views/BookList.vue'),
        meta: { title: '图书列表', requireAuth: true }
      },
      {
        path: 'book/:id',
        name: 'BookDetail',
        component: () => import('@/views/BookDetail.vue'),
        meta: { title: '图书详情', requireAuth: true }
      },
      {
        path: 'profile',
        name: 'Profile',
        component: () => import('@/views/Profile.vue'),
        meta: { title: '个人中心', requireAuth: true }
      },
      {
        path: 'admin/dashboard',
        name: 'AdminDashboard',
        component: () => import('@/views/admin/Dashboard.vue'),
        meta: { title: '后台首页', requireAuth: true, requireAdmin: true }
      },
      {
        path: 'admin/books',
        name: 'AdminBooks',
        component: () => import('@/views/admin/BookManage.vue'),
        meta: { title: '图书管理', requireAuth: true, requireAdmin: true }
      },
      {
        path: 'admin/categories',
        name: 'AdminCategories',
        component: () => import('@/views/admin/CategoryManage.vue'),
        meta: { title: '分类管理', requireAuth: true, requireAdmin: true }
      },
      {
        path: 'admin/borrows',
        name: 'AdminBorrows',
        component: () => import('@/views/admin/BorrowManage.vue'),
        meta: { title: '借阅记录管理', requireAuth: true, requireAdmin: true }
      },
      {
        path: 'admin/users',
        name: 'AdminUsers',
        component: () => import('@/views/admin/UserManage.vue'),
        meta: { title: '用户管理', requireAuth: true, requireAdmin: true }
      }
    ]
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/NotFound.vue'),
    meta: { title: '页面不存在', public: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 全局前置守卫: 登录拦截 + 角色控制
router.beforeEach((to, from, next) => {
  // 设置页面标题
  if (to.meta.title) {
    document.title = to.meta.title + ' - 图书管理系统'
  }
  const userStore = useUserStore()

  // 公开页面直接放行
  if (to.meta.public) {
    // 已登录用户访问登录/注册页, 跳转首页
    if ((to.name === 'Login' || to.name === 'Register') && userStore.isLogin) {
      return next('/')
    }
    return next()
  }

  // 需要登录
  if (to.meta.requireAuth && !userStore.isLogin) {
    ElMessage.warning('请先登录')
    return next('/login')
  }

  // 需要管理员权限
  if (to.meta.requireAdmin && !userStore.isAdmin) {
    ElMessage.error('权限不足,无法访问该页面')
    return next('/')
  }

  next()
})

export default router
