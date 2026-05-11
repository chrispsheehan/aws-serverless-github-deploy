import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

function localAuthConfigNoCache() {
  return {
    name: 'local-auth-config-no-cache',
    configureServer(server) {
      server.middlewares.use('/auth-config.json', (_req, res, next) => {
        res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate')
        next()
      })
    },
  }
}

const lambdaApiTarget = process.env.LOCAL_LAMBDA_API_URL || 'http://localhost:18080'
const ecsApiTarget = process.env.LOCAL_ECS_API_URL || 'http://localhost:18081'

export default defineConfig(({ command }) => ({
  plugins: [react(), command === 'serve' ? localAuthConfigNoCache() : null].filter(Boolean),
  server: {
    port: 5173,
    proxy: {
      '/api/ecs': {
        target: ecsApiTarget,
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/ecs/, '/ecs'),
      },
      '/api': {
        target: lambdaApiTarget,
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '') || '/',
      },
    },
  },
  build: {
    outDir: '../dist',
    emptyOutDir: true,
  },
}))
