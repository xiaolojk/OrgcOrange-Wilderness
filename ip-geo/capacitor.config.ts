import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.ipgeo.query',
  appName: 'IP 归属地查询',
  webDir: 'dist',

  // 关键：启用 CapacitorHttp（原生 HTTP）
  // · 绕过 WebView 的 CORS 限制，直连各查询接口
  // · 支持 http 明文源（ip-api.com）
  plugins: {
    CapacitorHttp: {
      enabled: true,
    },
    SplashScreen: {
      launchShowDuration: 600,
      backgroundColor: '#2563eb',
      showSpinner: false,
      splashFullScreen: true,
      splashImmersive: true,
    },
    StatusBar: {
      style: 'DARK',
      backgroundColor: '#2563eb',
      overlaysWebView: false,
    },
  },
  android: {
    allowMixedContent: true,
    backgroundColor: '#f4f6fb',
  },
};

export default config;
