import { defineConfig } from 'vite';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  base: './',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
  },
  server: {
    host: true,
    port: 5175,
  },
  plugins: [
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg'],
      manifest: {
        name: 'IP 归属地查询',
        short_name: 'IP查询',
        description: '功能齐全的 IP 归属地查询工具：IP/域名查询、批量查询、历史记录、收藏、深色模式',
        theme_color: '#2563eb',
        background_color: '#f5f7fb',
        display: 'standalone',
        orientation: 'portrait',
        start_url: './',
        lang: 'zh-CN',
        icons: [
          { src: 'icon.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any maskable' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,ico,png}'],
      },
    }),
  ],
});
