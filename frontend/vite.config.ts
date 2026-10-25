import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Backend target for the dev proxy. Defaults to localhost for plain host
// development; set VITE_PROXY_TARGET (e.g. http://backend:8000) in Docker.
const BACKEND_TARGET = process.env.VITE_PROXY_TARGET || 'http://localhost:8000'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: BACKEND_TARGET,
        changeOrigin: true,
      },
      // Pricing bundle JSON files are served by the backend (backend/static/pricing)
      '/static': {
        target: BACKEND_TARGET,
        changeOrigin: true,
      },
    },
  },
  build: {
    // Output directly to backend/static for deployment
    // This ensures the served files are always in sync with the build
    outDir: '../backend/static',
    emptyOutDir: false,  // Don't delete pricing/ folder and other static assets
    rollupOptions: {
      output: {
        // Keep assets in assets/ subfolder with content hashes for cache busting
        assetFileNames: 'assets/[name]-[hash][extname]',
        chunkFileNames: 'assets/[name]-[hash].js',
        entryFileNames: 'assets/[name]-[hash].js',
      }
    }
  }
})

