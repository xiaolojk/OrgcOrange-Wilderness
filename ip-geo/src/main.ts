import './style.css';
import { App } from './app';

/* ================= 入口 ================= */

const root = document.getElementById('app')!;
const app = new App(root);

// auto 主题下跟随系统深浅色实时切换（不重挂载，保留页面状态）
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => app.refreshTheme());
