import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

// Vite 配置
export default defineConfig({
  plugins: [vue()],
  // vitest 配置(仅在 npm test 时生效)
  test: {
    environment: 'jsdom',
    include: ['src/**/*.{test,spec}.js']
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  },
  build: {
    // 第三方依赖按库拆分为独立 chunk, 利用浏览器长期缓存, 避免业务改动导致整包失效
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes('node_modules')) return
          if (id.includes('node_modules/echarts') || id.includes('node_modules/zrender')) {
            return 'echarts'
          }
          if (id.includes('node_modules/element-plus') || id.includes('node_modules/@element-plus')) {
            return 'element-plus'
          }
          if (
            id.includes('node_modules/vue/') ||
            id.includes('node_modules/@vue') ||
            id.includes('node_modules/vue-router') ||
            id.includes('node_modules/pinia')
          ) {
            return 'vue-vendor'
          }
        }
      }
    }
  },
  server: {
    port: 5173,
    open: true,
    // 开发环境代理, 转发 /api 到后端
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      },
      '/uploads': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  },
  // 生产预览配置(npm run preview, 端口 4173), 与开发环境相同的代理规则
  preview: {
    port: 4173,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true
      },
      '/uploads': {
        target: 'http://localhost:8080',
        changeOrigin: true
      }
    }
  }
})
