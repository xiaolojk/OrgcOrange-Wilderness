import type { AppSettings, IpResult, RecordItem } from './types';

/* ================= 本地存储封装（localStorage） ================= */

const K_HISTORY = 'ipgeo.history.v1';
const K_FAVS = 'ipgeo.favs.v1';
const K_SETTINGS = 'ipgeo.settings.v1';
const MAX_HISTORY = 100;

function read<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

function write(key: string, value: unknown): void {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch { /* 存储满等异常忽略 */ }
}

/* ---------- 历史 ---------- */

export function getHistory(): RecordItem[] {
  return read<RecordItem[]>(K_HISTORY, []);
}

export function addHistory(result: IpResult): RecordItem[] {
  const list = getHistory().filter((it) => it.result.ip !== result.ip);
  list.unshift({ result });
  if (list.length > MAX_HISTORY) list.length = MAX_HISTORY;
  write(K_HISTORY, list);
  return list;
}

export function removeHistory(ip: string): RecordItem[] {
  const list = getHistory().filter((it) => it.result.ip !== ip);
  write(K_HISTORY, list);
  return list;
}

export function clearHistory(): void {
  write(K_HISTORY, []);
}

/* ---------- 收藏 ---------- */

export function getFavs(): RecordItem[] {
  return read<RecordItem[]>(K_FAVS, []);
}

export function isFav(ip: string): boolean {
  return getFavs().some((it) => it.result.ip === ip);
}

export function toggleFav(result: IpResult): { favs: RecordItem[]; fav: boolean } {
  const favs = getFavs();
  const idx = favs.findIndex((it) => it.result.ip === result.ip);
  if (idx >= 0) {
    favs.splice(idx, 1);
    write(K_FAVS, favs);
    return { favs, fav: false };
  }
  favs.unshift({ result, favTime: Date.now() });
  write(K_FAVS, favs);
  return { favs, fav: true };
}

export function removeFav(ip: string): RecordItem[] {
  const favs = getFavs().filter((it) => it.result.ip !== ip);
  write(K_FAVS, favs);
  return favs;
}

export function clearFavs(): void {
  write(K_FAVS, []);
}

/* ---------- 设置 ---------- */

const DEFAULT_SETTINGS: AppSettings = { theme: 'auto', haptics: true };

export function getSettings(): AppSettings {
  return { ...DEFAULT_SETTINGS, ...read<Partial<AppSettings>>(K_SETTINGS, {}) };
}

export function saveSettings(s: AppSettings): void {
  write(K_SETTINGS, s);
}
