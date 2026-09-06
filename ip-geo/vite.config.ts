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
        name: 'IP·GEO IP 归属地查询',
        short_name: 'IP·GEO',
        description: 'Bilingual IP geolocation with selectable data sources / 双语 IP 归属地查询，可自选数据源',
        theme_color: '#2563eb',
        background_color: '#f6f7f9',
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
