import type { AppSettings, IpResult, RecordItem } from './types';
import { queryIp, getMyIp, resolveDomain } from './api';
import {
  parseQueryTarget, flagEmoji, locationText, fmtTime, copyText, shareText,
} from './ipUtils';
import {
  getHistory, addHistory, removeHistory, clearHistory,
  getFavs, isFav, toggleFav, removeFav, clearFavs,
  getSettings, saveSettings,
} from './storage';

/* ================= UI 渲染与交互 ================= */

type TabId = 'query' | 'batch' | 'history' | 'favs' | 'settings';

const TABS: Array<{ id: TabId; icon: string; label: string }> = [
  { id: 'query', icon: '🔍', label: '查询' },
  { id: 'batch', icon: '📚', label: '批量' },
  { id: 'history', icon: '🕘', label: '历史' },
  { id: 'favs', icon: '⭐', label: '收藏' },
  { id: 'settings', icon: '⚙️', label: '设置' },
];

export class App {
  private root: HTMLElement;
  private settings: AppSettings;
  private currentTab: TabId = 'query';
  private currentResult: IpResult | null = null;
  private loading = false;
  private batchResults: IpResult[] = [];
  private batchTotal = 0;
  private batchDone = 0;

  constructor(root: HTMLElement) {
    this.root = root;
    this.settings = getSettings();
    this.applyTheme();
    this.render();
  }

  /* ---------- 主题 ---------- */

  private applyTheme(): void {
    const mode = this.settings.theme;
    const dark =
      mode === 'dark' ||
      (mode === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches);
    document.documentElement.dataset.theme = dark ? 'dark' : 'light';
    const meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute('content', dark ? '#0f1420' : '#2563eb');
  }

  /* ---------- 小工具 ---------- */

  private toast(msg: string): void {
    const el = document.createElement('div');
    el.className = 'toast';
    el.textContent = msg;
    document.body.appendChild(el);
    setTimeout(() => el.remove(), 1900);
  }

  private haptic(): void {
    if (!this.settings.haptics) return;
    try { navigator.vibrate?.(12); } catch { /* 不支持则忽略 */ }
  }

  private esc(s: unknown): string {
    return String(s ?? '').replace(/[&<>"']/g, (c) =>
      ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c] as string));
  }

  /* ---------- 渲染骨架 ---------- */

  private render(): void {
    this.root.innerHTML = `
      <header class="app-header">
        <div class="logo">🌐</div>
        <h1>IP 归属地查询</h1>
        <button class="header-btn" id="btn-myip">📍 我的IP</button>
      </header>
      <main id="tab-content"></main>
      <nav class="tabbar"><div class="tabbar-inner" id="tabbar"></div></nav>
    `;
    this.renderTabbar();
    this.renderTab();
    document.getElementById('btn-myip')!.addEventListener('click', () => this.onMyIp());
  }

  private renderTabbar(): void {
    const bar = document.getElementById('tabbar')!;
    bar.innerHTML = TABS.map(
      (t) => `<button class="tab-item ${t.id === this.currentTab ? 'on' : ''}" data-tab="${t.id}">
        <span class="icon">${t.icon}</span><span>${t.label}</span></button>`
    ).join('');
    bar.querySelectorAll('.tab-item').forEach((b) =>
      b.addEventListener('click', () => {
        this.currentTab = (b as HTMLElement).dataset.tab as TabId;
        this.haptic();
        this.renderTabbar();
        this.renderTab();
      })
    );
  }

  private renderTab(): void {
    const main = document.getElementById('tab-content')!;
    switch (this.currentTab) {
      case 'query': this.renderQueryTab(main); break;
      case 'batch': this.renderBatchTab(main); break;
      case 'history': this.renderHistoryTab(main); break;
      case 'favs': this.renderFavsTab(main); break;
      case 'settings': this.renderSettingsTab(main); break;
    }
  }

  /* ================= Tab：查询 ================= */

  private renderQueryTab(main: HTMLElement): void {
    const history = getHistory().slice(0, 6);
    main.innerHTML = `
      <div class="search-box">
        <div class="search-row">
          <input class="search-input" id="q-input" placeholder="输入 IP 地址或域名，如 8.8.8.8 / baidu.com"
            autocomplete="off" autocapitalize="off" spellcheck="false">
          <button class="btn btn-primary" id="q-btn">查询</button>
        </div>
        <div class="search-tips" id="q-tips">
          ${history.map((h) => `<span class="tip-chip" data-ip="${this.esc(h.result.ip)}">${this.esc(h.result.ip)}</span>`).join('')}
        </div>
      </div>
      <div id="q-status"></div>
    `;
    const input = document.getElementById('q-input') as HTMLInputElement;
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') this.onQuery(input.value); });
    document.getElementById('q-btn')!.addEventListener('click', () => this.onQuery(input.value));
    document.getElementById('q-tips')!.querySelectorAll('.tip-chip').forEach((c) =>
      c.addEventListener('click', () => { input.value = (c as HTMLElement).dataset.ip!; this.onQuery(input.value); })
    );
    // 当前有结果则直接展示
    if (this.currentResult) this.renderResult(this.currentResult);
  }

  private async onQuery(raw: string): Promise<void> {
    const target = parseQueryTarget(raw);
    if (target.kind === 'invalid') { this.toast('❌ 请输入合法的 IP 或域名'); return; }

    const status = document.getElementById('q-status')!;
    this.haptic();
    this.loading = true;

    if (target.kind === 'private') {
      this.currentResult = {
        ip: target.value, country: '局域网 / 保留地址', isPrivate: true,
        privateType: target.type, source: '本地识别', time: Date.now(),
      };
      addHistory(this.currentResult);
      this.loading = false;
      this.renderResult(this.currentResult);
      this.refreshTipChips();
      return;
    }

    status.innerHTML = `<div class="loading-box"><div class="spinner"></div>
      ${target.kind === 'domain' ? `正在解析域名 ${this.esc(target.value)} …` : '正在查询，稍候…'}</div>`;
    try {
      let ip = target.value;
      if (target.kind === 'domain') {
        status.innerHTML = `<div class="loading-box"><div class="spinner"></div>正在解析域名 ${this.esc(target.value)} …</div>`;
        ip = await resolveDomain(target.value);
      }
      status.innerHTML = `<div class="loading-box"><div class="spinner"></div>正在查询 ${this.esc(ip)} 的归属地…</div>`;
      const result = await queryIp(ip);
      this.currentResult = result;
      addHistory(result);
      status.innerHTML = '';
      this.renderResult(result);
      this.refreshTipChips();
    } catch (e) {
      status.innerHTML = `<div class="error-box">❌ ${this.esc(e instanceof Error ? e.message : '查询失败，请检查网络')}</div>`;
    } finally {
      this.loading = false;
    }
  }

  private async onMyIp(): Promise<void> {
    const btn = document.getElementById('btn-myip') as HTMLButtonElement;
    btn.disabled = true;
    this.haptic();
    try {
      const ip = await getMyIp();
      // 切到查询页并填入
      this.currentTab = 'query';
      this.renderTabbar();
      this.renderTab();
      const input = document.getElementById('q-input') as HTMLInputElement | null;
      if (input) input.value = ip;
      await this.onQuery(ip);
    } catch (e) {
      this.toast(`❌ ${e instanceof Error ? e.message : '获取失败'}`);
    } finally {
      btn.disabled = false;
    }
  }

  private refreshTipChips(): void {
    // 只刷新快捷 chips，不动输入框与结果
    const tips = document.getElementById('q-tips');
    if (!tips) return;
    const history = getHistory().slice(0, 6);
    tips.innerHTML = history
      .map((h) => `<span class="tip-chip" data-ip="${this.esc(h.result.ip)}">${this.esc(h.result.ip)}</span>`)
      .join('');
    tips.querySelectorAll('.tip-chip').forEach((c) =>
      c.addEventListener('click', () => {
        const input = document.getElementById('q-input') as HTMLInputElement;
        input.value = (c as HTMLElement).dataset.ip!;
        this.onQuery(input.value);
      })
    );
  }

  private renderResult(r: IpResult): void {
    const host = document.getElementById('q-status') ?? document.getElementById('tab-content')!;
    const fav = isFav(r.ip);
    const rows: Array<[string, string | undefined]> = [
      ['归属地', locationText(r) || '未知'],
      ['国家/地区', r.country],
      ['省 / 州', r.region],
      ['城市', r.city],
      ['区县', r.district],
      ['运营商', r.isp],
      ['ASN', r.asn],
      ['组织', r.org],
      ['经纬度', r.lat != null && r.lon != null ? `${r.lat}, ${r.lon}` : undefined],
      ['时区', r.timezone],
      ['邮编', r.zipcode],
      ['数据源', r.source],
      ['查询时间', fmtTime(r.time)],
    ];
    if (r.isPrivate) rows.unshift(['地址类型', r.privateType ?? '内网地址']);
    host.innerHTML = `
      <div class="result-card">
        <div class="result-head">
          <div class="result-flag">${r.isPrivate ? '🏠' : flagEmoji(r.countryCode)}</div>
          <div class="result-ip-block">
            <div class="result-ip">${this.esc(r.ip)}</div>
            <div class="result-loc">${this.esc(locationText(r) || (r.isPrivate ? '局域网地址，无公网归属地' : '未知'))}</div>
          </div>
          <span class="result-badge ${r.isPrivate ? 'private' : ''}">${r.isPrivate ? '内网' : (r.countryCode ? this.esc(r.countryCode) : 'IP')}</span>
        </div>
        <div class="detail-list">
          ${rows.filter(([, v]) => v != null && v !== '').map(([k, v]) => `
            <div class="detail-row">
              <div class="detail-label">${k}</div>
              <div class="detail-value"><span>${this.esc(v)}</span>
                <span class="copy-icon" data-copy="${this.esc(v)}" title="复制">📋</span>
              </div>
            </div>`).join('')}
        </div>
        <div class="result-actions">
          <button class="btn-mini" id="r-copy">📋 复制结果</button>
          <button class="btn-mini" id="r-share">📤 分享</button>
          <button class="btn-mini ${fav ? 'warn' : ''}" id="r-fav">${fav ? '⭐ 已收藏' : '☆ 收藏'}</button>
          ${r.lat != null && r.lon != null ? `
            <button class="btn-mini" id="r-map-amap">🗺️ 高德地图</button>
            <button class="btn-mini" id="r-map-g">🌍 Google 地图</button>` : ''}
        </div>
      </div>`;
    host.querySelectorAll('.copy-icon').forEach((c) =>
      c.addEventListener('click', async () => {
        const ok = await copyText((c as HTMLElement).dataset.copy!);
        this.toast(ok ? '✅ 已复制' : '❌ 复制失败');
      })
    );
    document.getElementById('r-copy')?.addEventListener('click', async () => {
      const ok = await copyText(this.resultText(r));
      this.toast(ok ? '✅ 已复制结果' : '❌ 复制失败');
    });
    document.getElementById('r-share')?.addEventListener('click', async () => {
      const ok = await shareText(this.resultText(r));
      if (!ok) { await copyText(this.resultText(r)); this.toast('已复制，可粘贴分享'); }
    });
    document.getElementById('r-fav')?.addEventListener('click', () => {
      const { fav: now } = toggleFav(r);
      this.haptic();
      this.toast(now ? '⭐ 已加入收藏' : '已取消收藏');
      this.renderResult(r);
    });
    document.getElementById('r-map-amap')?.addEventListener('click', () =>
      window.open(`https://uri.amap.com/marker?position=${r.lon},${r.lat}&name=${encodeURIComponent(r.ip)}&src=ipgeo`, '_blank'));
    document.getElementById('r-map-g')?.addEventListener('click', () =>
      window.open(`https://www.google.com/maps?q=${r.lat},${r.lon}`, '_blank'));
  }

  private resultText(r: IpResult): string {
    const lines = [
      `IP：${r.ip}`,
      `归属地：${locationText(r) || (r.isPrivate ? '局域网地址' : '未知')}`,
      r.isp && `运营商：${r.isp}`,
      r.asn && `ASN：${r.asn}`,
      r.lat != null && `经纬度：${r.lat}, ${r.lon}`,
      r.timezone && `时区：${r.timezone}`,
      `数据源：${r.source}`,
      `—— IP 归属地查询`,
    ];
    return lines.filter(Boolean).join('\n');
  }

  /* ================= Tab：批量 ================= */

  private renderBatchTab(main: HTMLElement): void {
    main.innerHTML = `
      <div class="search-box">
        <textarea class="batch-textarea" id="b-input"
          placeholder="每行一个 IP 或域名，例如：&#10;8.8.8.8&#10;baidu.com&#10;114.114.114.114&#10;2400:3200::1"></textarea>
        <div style="display:flex;gap:10px;margin-top:10px;">
          <button class="btn btn-primary" id="b-btn" style="flex:1;">🚀 开始批量查询</button>
          <button class="btn btn-ghost" id="b-clear">清空</button>
        </div>
        <div class="batch-progress" id="b-prog" style="display:none;"><div class="bar" id="b-bar"></div></div>
        <div class="batch-stats" id="b-stats"></div>
      </div>
      <div class="section-title">查询结果 <span class="count" id="b-count"></span>
        <span class="grow"></span>
        <button class="btn-mini" id="b-export" style="display:none;">📋 复制全部</button>
      </div>
      <div class="record-list" id="b-list"></div>
    `;
    document.getElementById('b-btn')!.addEventListener('click', () => this.onBatch());
    document.getElementById('b-clear')!.addEventListener('click', () => {
      (document.getElementById('b-input') as HTMLTextAreaElement).value = '';
      this.batchResults = [];
      this.renderBatchList();
      this.toast('已清空');
    });
    document.getElementById('b-export')!.addEventListener('click', async () => {
      const text = this.batchResults
        .map((r) => `${r.ip}\t${locationText(r) || (r.isPrivate ? '内网' : '查询失败')}`)
        .join('\n');
      const ok = await copyText(text);
      this.toast(ok ? '✅ 已复制全部结果' : '❌ 复制失败');
    });
    this.renderBatchList();
  }

  private async onBatch(): Promise<void> {
    const input = document.getElementById('b-input') as HTMLTextAreaElement;
    const lines = input.value.split(/\n+/).map((s) => s.trim()).filter(Boolean);
    if (!lines.length) { this.toast('请先输入要查询的 IP / 域名'); return; }
    if (lines.length > 200) { this.toast('单次最多 200 条'); return; }

    this.haptic();
    this.batchResults = [];
    this.batchTotal = lines.length;
    this.batchDone = 0;
    const prog = document.getElementById('b-prog')!;
    prog.style.display = 'block';
    const bar = document.getElementById('b-bar') as HTMLElement;

    // 3 并发依次查询，兼顾速度与接口压力
    const queue = [...lines];
    const worker = async () => {
      while (queue.length) {
        const line = queue.shift()!;
        let result: IpResult | null = null;
        try {
          const target = parseQueryTarget(line);
          if (target.kind === 'invalid') {
            result = { ip: line, country: '格式错误', source: '-', time: Date.now() };
          } else if (target.kind === 'private') {
            result = { ip: target.value, country: '局域网 / 保留地址', isPrivate: true, privateType: target.type, source: '本地识别', time: Date.now() };
          } else {
            const ip = target.kind === 'domain' ? await resolveDomain(target.value) : target.value;
            result = await queryIp(ip);
          }
        } catch {
          result = { ip: line, country: '查询失败', source: '-', time: Date.now() };
        }
        this.batchResults.push(result);
        this.batchDone++;
        bar.style.width = `${(this.batchDone / this.batchTotal) * 100}%`;
        this.renderBatchList();
      }
    };
    await Promise.all([worker(), worker(), worker()]);
    prog.style.display = 'none';
    this.toast(`✅ 批量查询完成（${this.batchTotal} 条）`);
  }

  private renderBatchList(): void {
    const list = document.getElementById('b-list');
    const count = document.getElementById('b-count');
    const exportBtn = document.getElementById('b-export');
    if (!list) return;
    if (count) count.textContent = this.batchResults.length ? `${this.batchResults.length} 条` : '';
    if (exportBtn) exportBtn.style.display = this.batchResults.length ? '' : 'none';
    list.innerHTML = this.batchResults.map((r) => `
      <div class="record-item" data-ip="${this.esc(r.ip)}">
        <div class="record-main">
          <div class="record-ip">${r.isPrivate ? '🏠' : flagEmoji(r.countryCode)} ${this.esc(r.ip)}</div>
          <div class="record-sub">${this.esc(locationText(r) || '—')}</div>
        </div>
        <span class="record-time">${this.esc(r.isp ?? r.source ?? '')}</span>
      </div>`).join('');
    list.querySelectorAll('.record-item').forEach((it) =>
      it.addEventListener('click', () => {
        this.currentTab = 'query';
        this.renderTabbar();
        this.renderTab();
        const input = document.getElementById('q-input') as HTMLInputElement;
        input.value = (it as HTMLElement).dataset.ip!;
        this.onQuery(input.value);
      })
    );
  }

  /* ================= Tab：历史 ================= */

  private renderHistoryTab(main: HTMLElement): void {
    const history = getHistory();
    main.innerHTML = `
      <div class="section-title">🕘 查询历史
        <span class="count">${history.length} 条（最多保留 100 条）</span>
        <span class="grow"></span>
        ${history.length ? '<button class="btn-mini danger" id="h-clear">🗑️ 清空</button>' : ''}
      </div>
      <div class="record-list" id="h-list"></div>
    `;
    const list = document.getElementById('h-list')!;
    if (!history.length) {
      list.innerHTML = `<div class="empty-box"><div class="big">🗂️</div>暂无查询记录</div>`;
    } else {
      list.innerHTML = history.map((h) => this.recordItemHtml(h)).join('');
      this.bindRecordItems(list, 'h', removeHistory);
    }
    document.getElementById('h-clear')?.addEventListener('click', () => {
      clearHistory();
      this.toast('历史已清空');
      this.renderTab();
    });
  }

  /* ================= Tab：收藏 ================= */

  private renderFavsTab(main: HTMLElement): void {
    const favs = getFavs();
    main.innerHTML = `
      <div class="section-title">⭐ 我的收藏
        <span class="count">${favs.length} 条</span>
        <span class="grow"></span>
        ${favs.length ? '<button class="btn-mini danger" id="f-clear">🗑️ 清空</button>' : ''}
      </div>
      <div class="record-list" id="f-list"></div>
    `;
    const list = document.getElementById('f-list')!;
    if (!favs.length) {
      list.innerHTML = `<div class="empty-box"><div class="big">⭐</div>还没有收藏<br>查询结果页点击「☆ 收藏」即可加入</div>`;
    } else {
      list.innerHTML = favs.map((h) => this.recordItemHtml(h)).join('');
      this.bindRecordItems(list, 'f', removeFav);
    }
    document.getElementById('f-clear')?.addEventListener('click', () => {
      clearFavs();
      this.toast('收藏已清空');
      this.renderTab();
    });
  }

  private recordItemHtml(it: RecordItem): string {
    const r = it.result;
    return `
      <div class="record-item" data-ip="${this.esc(r.ip)}">
        <div class="record-main">
          <div class="record-ip">${r.isPrivate ? '🏠' : flagEmoji(r.countryCode)} ${this.esc(r.ip)}</div>
          <div class="record-sub">${this.esc(locationText(r) || (r.isPrivate ? r.privateType ?? '内网地址' : '未知'))}</div>
        </div>
        <span class="record-time">${fmtTime(r.time)}</span>
        <button class="record-del" data-del="${this.esc(r.ip)}" title="删除">✕</button>
      </div>`;
  }

  /** 绑定记录列表：点卡片→查详情，点删除→移除 */
  private bindRecordItems(
    list: HTMLElement,
    prefix: string,
    removeFn: (ip: string) => RecordItem[]
  ): void {
    list.querySelectorAll('.record-del').forEach((b) =>
      b.addEventListener('click', (e) => {
        e.stopPropagation();
        const ip = (b as HTMLElement).dataset.del!;
        removeFn(ip);
        this.toast('已删除');
        this.renderTab();
      })
    );
    list.querySelectorAll('.record-item').forEach((it) =>
      it.addEventListener('click', () => {
        this.currentTab = 'query';
        this.renderTabbar();
        this.renderTab();
        const input = document.getElementById('q-input') as HTMLInputElement;
        input.value = (it as HTMLElement).dataset.ip!;
        this.onQuery(input.value);
      })
    );
    void prefix;
  }

  /* ================= Tab：设置 ================= */

  private renderSettingsTab(main: HTMLElement): void {
    main.innerHTML = `
      <div class="section-title">⚙️ 设置</div>
      <div class="settings-card">
        <div class="setting-row">
          <div class="setting-label">外观主题
            <div class="setting-sub">跟随系统或手动指定</div>
          </div>
          <div class="seg" id="s-theme">
            <button data-v="auto" class="${this.settings.theme === 'auto' ? 'on' : ''}">自动</button>
            <button data-v="light" class="${this.settings.theme === 'light' ? 'on' : ''}">浅色</button>
            <button data-v="dark" class="${this.settings.theme === 'dark' ? 'on' : ''}">深色</button>
          </div>
        </div>
        <div class="setting-row">
          <div class="setting-label">震动反馈
            <div class="setting-sub">操作时轻微震动</div>
          </div>
          <button class="toggle ${this.settings.haptics ? 'on' : ''}" id="s-haptics"></button>
        </div>
        <div class="setting-row" id="s-data">
          <div class="setting-label">数据管理
            <div class="setting-sub">清空历史与收藏</div>
          </div>
          <button class="btn-mini danger" id="s-clear-all">🗑️ 清空数据</button>
        </div>
      </div>

      <div class="section-title">🌐 数据源（自动容错切换）</div>
      <div class="settings-card">
        <div class="setting-row"><div class="setting-label">① vore.top<div class="setting-sub">国内 · HTTPS · 中文含运营商</div></div></div>
        <div class="setting-row"><div class="setting-label">② ip-api.com<div class="setting-sub">国际 · 中文输出 · 字段全</div></div></div>
        <div class="setting-row"><div class="setting-label">③ ipwho.is<div class="setting-sub">国际 · HTTPS · 经纬度/ASN</div></div></div>
        <div class="setting-row"><div class="setting-label">④ ipapi.co<div class="setting-sub">国际 · 兜底</div></div></div>
      </div>

      <div class="about-box">
        IP 归属地查询 v1.0.0<br>
        支持查询 IPv4 / IPv6 / 域名 · 内网识别 · 批量查询 · 历史收藏<br>
        Capacitor + Vite · 数据仅供参考
      </div>
    `;
    document.getElementById('s-theme')!.querySelectorAll('button').forEach((b) =>
      b.addEventListener('click', () => {
        this.settings.theme = (b as HTMLElement).dataset.v as AppSettings['theme'];
        saveSettings(this.settings);
        this.applyTheme();
        this.haptic();
        this.renderTab();
      })
    );
    document.getElementById('s-haptics')!.addEventListener('click', () => {
      this.settings.haptics = !this.settings.haptics;
      saveSettings(this.settings);
      this.haptic();
      this.renderTab();
    });
    document.getElementById('s-clear-all')!.addEventListener('click', () => {
      clearHistory();
      clearFavs();
      this.toast('已清空全部历史与收藏');
      this.renderTab();
    });
  }
}
