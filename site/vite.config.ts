import react from '@vitejs/plugin-react'
import { resolve } from 'node:path'
import { defineConfig } from 'vite'

// Served from GitHub Pages at /near-miss/. Two pages: the landing and the privacy policy.
export default defineConfig({
  base: process.env.SITE_BASE ?? '/near-miss/',
  plugins: [react()],
  build: {
    rollupOptions: {
      input: {
        main: resolve(import.meta.dirname, 'index.html'),
        privacidad: resolve(import.meta.dirname, 'privacidad/index.html'),
      },
    },
  },
})
