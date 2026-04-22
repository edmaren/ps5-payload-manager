import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { viteSingleFile } from 'vite-plugin-singlefile'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(), viteSingleFile()],
  build: {
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
      },
      format: {
        comments: false,
      },
    },
    cssCodeSplit: false,
    assetsInlineLimit: 100000, // Inline all assets
  },
  server: {
    proxy: {
      '/getip': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/version': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/list_payloads': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/autoload_status': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/get_config': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/set_config': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/loadpayload:': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/manage:': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/abort': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/autoload_clear': { target: 'http://127.0.0.1:8081', changeOrigin: true },
      '/events': {
        target: 'http://127.0.0.1:8081',
        changeOrigin: true,
        sse: true
      }
    }
  }
})
