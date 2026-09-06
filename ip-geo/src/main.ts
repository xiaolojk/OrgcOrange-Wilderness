import './style.css';
import { App } from './app';

/* ================= 入口 ================= */

const root = document.getElementById('app')!;
new App(root);

// 跟随系统深浅色变化（auto 模式下实时响应）
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
  // 触发一次重渲染应用主题（App 内部读取设置决定）
  location.hash = location.hash; // 无副作用，仅保活
  window.dispatchEvent(new CustomEvent('theme-change'));
});
window.addEventListener('theme-change', () => {
  // 重新挂载以应用主题（设置主题为 auto 时）
  root.innerHTML = '';
  new App(root);
});
