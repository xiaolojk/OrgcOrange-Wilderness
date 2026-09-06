import type { AppSettings, IpResult, QuerySource, RecordItem } from './types';
import { queryIp, getMyIp, resolveDomain, SOURCE_META } from './api';
import {
  parseQueryTarget, flagEmoji, locationText, fmtTime, copyText, shareText,
} from './ipUtils';
import {
  getHistory, addHistory, removeHistory, clearHistory,
  getFavs, isFav, toggleFav, removeFav, clearFavs,
  getSettings, saveSettings,
} from './storage';
import { T, type Dict } from './i18n';

/* ================= UI 渲染与交互（双语 + 可选数据源） ================= */

type TabId = 'query' | 'batch' | 'history' | 'favs' | 'settings';

const TABS: ReadonlyArray<{ id: TabId; icon: string; k: keyof Dict }> = [
  { id: 'query', icon: '◎', k: 'tabQuery' },
  { id: 'batch', icon: '☰', k: 'tabBatch' },
  { id: 'history', icon: '◷', k: 'tabHistory' },
  { id: 'favs', icon: '★', k: 'tabFavs' },
  { id: 'settings', icon: '⚙', k: 'tabSettings' },
];

/** 数据源 id → i18n 描述键 */
const SRC_KEY: Record<string, keyof Dict> = {
  vore: 'srcVore', ipapi: 'srcIpapi', ipwho: 'srcIpwho', ipapico: 'srcIpapico',
};

export class App {
  private root: HTMLElement;
  private settings: AppSettings;
  private tab: TabId = 'query';
  private result: IpResult | null = null;
  private busy = false;
  private batch: IpResult[] = [];
  private batchTotal = 0;
  private batchDone = 0;

  constructor(root: HTMLElement) {
    this.root = root;
    this.settings = getSettings();
    this.applyTheme();
    this.render();
  }

  /* ---------- 基础 ---------- */

  private get tr(): Dict { return T[this.settings.lang]; }

  private isDark(): boolean {
    const m = this.settings.theme;
    return m === 'dark' || (m === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches);
  }

  private applyTheme(): void {
    document.documentElement.dataset.theme = this.isDark() ? 'dark' : 'light';
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', this.isDark() ? '#0b0d12' : '#f6f7f9');
  }

  /** 系统深浅色变化时由外部调用（auto 模式下实时生效） */
  refreshTheme(): void {
    this.applyTheme();
    this.renderHeader();
  }

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

  /* ---------- 骨架 ---------- */

  private render(): void {
    this.root.innerHTML = `
      <header class="topbar" id="topbar"></header>
      <main id="main"></main>
      <nav class="tabbar"><div class="tabbar-inner" id="tabbar"></div></nav>
    `;
    this.renderHeader();
    this.renderTabbar();
    this.renderTab();
  }

  private renderHeader(): void {
    const bar = this.root.querySelector('#topbar')!;
    const langBtn = this.settings.lang === 'zh' ? 'EN' : '中文';
    bar.innerHTML = `
      <div class="brand">
        <div class="brand-mark">◈</div>
        <div class="brand-text">
          <div class="brand-name">IP·GEO</div>
          <div class="brand-sub">${this.esc(this.tr.appName)}</div>
        </div>
      </div>
      <button class="pill-btn" id="btn-myip" title="${this.esc(this.tr.myIp)}">⌖ <span class="myip-t">${this.esc(this.tr.myIp)}</span></button>
      <button class="pill-btn" id="btn-lang" title="Language / 语言">${langBtn}</button>
      <button class="pill-btn" id="btn-theme" title="${this.esc(this.tr.appearance)}">${this.isDark() ? '☾' : '☀'}</button>
    `;
    bar.querySelector('#btn-myip')!.addEventListener('click', () => void this.onMyIp());
    bar.querySelector('#btn-lang')!.addEventListener('click', () => {
      this.settings.lang = this.settings.lang === 'zh' ? 'en' : 'zh';
      saveSettings(this.settings);
      this.haptic();
      this.render();
    });
    bar.querySelector('#btn-theme')!.addEventListener('click', () => {
      this.settings.theme = this.isDark() ? 'light' : 'dark';
      saveSettings(this.settings);
      this.applyTheme();
      this.renderHeader();
    });
  }

  private renderTabbar(): void {
    const bar = this.root.querySelector('#tabbar')!;
    bar.innerHTML = TABS.map((t) =>
      `<button class="tab ${t.id === this.tab ? 'on' : ''}" data-tab="${t.id}">
        <span class="ic">${t.icon}</span><span>${this.esc(this.tr[t.k])}</span></button>`).join('');
    bar.querySelectorAll('.tab').forEach((b) =>
      b.addEventListener('click', () => {
        this.tab = (b as HTMLElement).dataset.tab as TabId;
        this.haptic();
        this.renderTabbar();
        this.renderTab();
      }));
  }

  private renderTab(): void {
    const main = this.root.querySelector('#main') as HTMLElement;
    switch (this.tab) {
      case 'query': this.renderQueryTab(main); break;
      case 'batch': this.renderBatchTab(main); break;
      case 'history': this.renderHistoryTab(main); break;
      case 'favs': this.renderFavsTab(main); break;
      case 'settings': this.renderSettingsTab(main); break;
    }
  }

  /* ================= Tab：查询 ================= */

  private renderQueryTab(main: HTMLElement): void {
    const recent = getHistory().slice(0, 5);
    main.innerHTML = `
      <section class="panel">
        <div class="search-row">
          <input id="q-input" class="input mono" placeholder="${this.esc(this.tr.searchPlaceholder)}"
            autocomplete="off" autocapitalize="off" spellcheck="false">
          <button id="q-btn" class="btn-primary">${this.esc(this.tr.query)}</button>
        </div>
        <div class="source-row">
          <span class="source-label">${this.esc(this.tr.sourceLabel)}</span>
          <div class="seg" id="src-seg">
            <button data-src="auto" class="${this.settings.source === 'auto' ? 'on' : ''}">${this.esc(this.tr.auto)}</button>
            ${SOURCE_META.map((s) =>
              `<button data-src="${s.id}" class="${this.settings.source === s.id ? 'on' : ''}">${s.name}</button>`).join('')}
          </div>
        </div>
        <div class="chips" id="q-tips" style="display:${recent.length ? 'flex' : 'none'}">
          ${recent.map((h) => `<span class="chip" data-ip="${this.esc(h.result.ip)}">${this.esc(h.result.ip)}</span>`).join('')}
        </div>
      </section>
      <div id="q-status"></div>
    `;
    const input = main.querySelector('#q-input') as HTMLInputElement;
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') void this.onQuery(input.value); });
    main.querySelector('#q-btn')!.addEventListener('click', () => void this.onQuery(input.value));
    main.querySelectorAll('#src-seg button').forEach((b) =>
      b.addEventListener('click', () => this.setSource((b as HTMLElement).dataset.src as QuerySource)));
    this.bindChips();
    if (this.result) this.renderResult(this.result);
  }

  /** 切换数据源（保留输入与已显示结果） */
  private setSource(src: QuerySource): void {
    if (this.settings.source === src) return;
    this.settings.source = src;
    saveSettings(this.settings);
    this.haptic();
    const val = (document.getElementById('q-input') as HTMLInputElement | null)?.value ?? '';
    this.renderTab();
    const input = document.getElementById('q-input') as HTMLInputElement | null;
    if (input && val) input.value = val;
    if (this.result) this.renderResult(this.result);
  }

  private bindChips(): void {
    document.querySelectorAll('#q-tips .chip').forEach((c) =>
      c.addEventListener('click', () => {
        const ip = (c as HTMLElement).dataset.ip!;
        const input = document.getElementById('q-input') as HTMLInputElement;
        input.value = ip;
        void this.onQuery(ip);
      }));
  }

  private refreshChips(): void {
    const host = document.getElementById('q-tips');
    if (!host) return;
    const recent = getHistory().slice(0, 5);
    host.innerHTML = recent.map((h) =>
      `<span class="chip" data-ip="${this.esc(h.result.ip)}">${this.esc(h.result.ip)}</span>`).join('');
    host.style.display = recent.length ? 'flex' : 'none';
    this.bindChips();
  }

  private async onQuery(raw: string): Promise<void> {
    if (this.busy) return;
    const target = parseQueryTarget(raw);
    if (target.kind === 'invalid') { this.toast(this.tr.invalid); return; }
    const status = document.getElementById('q-status');
    if (!status) return;
    const btn = document.getElementById('q-btn') as HTMLButtonElement | null;
    this.haptic();
    this.busy = true;
    if (btn) btn.disabled = true;

    try {
      if (target.kind === 'private') {
        this.result = {
          ip: target.value, country: this.tr.privateNet, isPrivate: true,
          privateType: target.type, source: 'Local', time: Date.now(),
        };
        addHistory(this.result);
        this.renderResult(this.result);
        this.refreshChips();
        return;
      }
      status.innerHTML = `<div class="loading"><div class="spinner"></div><div>${
        target.kind === 'domain'
          ? `${this.esc(this.tr.resolving)} ${this.esc(target.value)} …`
          : `${this.esc(this.tr.querying)} ${this.esc(target.value)} …`
      }</div></div>`;
      let ip = target.value;
      if (target.kind === 'domain') ip = await resolveDomain(target.value);
      status.innerHTML = `<div class="loading"><div class="spinner"></div><div>${this.esc(this.tr.querying)} ${this.esc(ip)} …</div></div>`;
      const r = await queryIp(ip, this.settings.source);
      this.result = r;
      addHistory(r);
      status.innerHTML = '';
      this.renderResult(r);
      this.refreshChips();
    } catch (e) {
      status.innerHTML = `<div class="error">✕ ${this.esc(e instanceof Error ? e.message : this.tr.lookupFail)}</div>`;
    } finally {
      this.busy = false;
      if (btn) btn.disabled = false;
    }
  }

  private async onMyIp(): Promise<void> {
    const btn = document.getElementById('btn-myip') as HTMLButtonElement | null;
    if (btn) btn.disabled = true;
    this.haptic();
    try {
      const ip = await getMyIp();
      this.tab = 'query';
      this.renderTabbar();
      this.renderTab();
      const input = document.getElementById('q-input') as HTMLInputElement | null;
      if (input) input.value = ip;
      await this.onQuery(ip);
    } catch (e) {
      this.toast(`✕ ${e instanceof Error ? e.message : this.tr.lookupFail}`);
    } finally {
      if (btn) btn.disabled = false;
    }
  }

  /** 跳到查询页并查询（历史/收藏/批量点击复用） */
  private gotoQuery(ip: string): void {
    this.tab = 'query';
    this.renderTabbar();
    this.renderTab();
    const input = document.getElementById('q-input') as HTMLInputElement | null;
    if (input) input.value = ip;
    void this.onQuery(ip);
  }

  private renderResult(r: IpResult): void {
    const host = document.getElementById('q-status');
    if (!host) return;
    const tr = this.tr;
    const fav = isFav(r.ip);
    const rows: Array<[string, string | undefined]> = [
      [tr.fieldLocation, locationText(r) || (r.isPrivate ? tr.noGeo : tr.unknown)],
      [tr.fieldCountry, r.country],
      [tr.fieldRegion, r.region],
      [tr.fieldCity, r.city],
      [tr.fieldDistrict, r.district],
      [tr.fieldIsp, r.isp],
      [tr.fieldAsn, r.asn],
      [tr.fieldOrg, r.org],
      [tr.fieldCoords, r.lat != null && r.lon != null ? `${r.lat}, ${r.lon}` : undefined],
      [tr.fieldTimezone, r.timezone],
      [tr.fieldZip, r.zipcode],
      [tr.fieldSource, r.source],
      [tr.fieldTime, fmtTime(r.time)],
    ];
    if (r.isPrivate) rows.unshift([tr.fieldType, r.privateType ?? tr.privateNet]);

    host.innerHTML = `
      <section class="panel fade-up">
        <div class="result-hero">
          <div class="flag">${r.isPrivate ? '⌂' : flagEmoji(r.countryCode)}</div>
          <div class="result-main">
            <div class="result-ip">${this.esc(r.ip)}</div>
            <div class="result-loc">${this.esc(locationText(r) || (r.isPrivate ? tr.noGeo : tr.unknown))}</div>
          </div>
          <span class="badge ${r.isPrivate ? 'private' : ''}">${r.isPrivate ? this.esc(tr.privateTag) : (r.countryCode ? this.esc(r.countryCode) : 'IP')}</span>
        </div>
        <div class="rows">
          ${rows.filter(([, v]) => v != null && v !== '').map(([k, v]) => `
            <div class="row">
              <span class="row-k">${this.esc(k)}</span>
              <span class="row-v"><span>${this.esc(v)}</span><span class="copy-ic" data-copy="${this.esc(v)}">⧉</span></span>
            </div>`).join('')}
        </div>
        <div class="result-actions">
          <button class="act" id="r-copy">⧉ ${this.esc(tr.copyResult)}</button>
          <button class="act" id="r-share">↗ ${this.esc(tr.share)}</button>
          <button class="act ${fav ? 'on' : ''}" id="r-fav">${fav ? '★' : '☆'} ${this.esc(fav ? tr.starred : tr.star)}</button>
          ${r.lat != null && r.lon != null ? `
            <button class="act" id="r-amap">🗺 ${this.esc(tr.amap)}</button>
            <button class="act" id="r-g">🌐 ${this.esc(tr.gmap)}</button>` : ''}
        </div>
      </section>`;

    host.querySelectorAll('.copy-ic').forEach((c) =>
      c.addEventListener('click', async () => {
        const ok = await copyText((c as HTMLElement).dataset.copy!);
        this.toast(ok ? tr.copied : tr.copyFail);
      }));
    host.querySelector('#r-copy')?.addEventListener('click', async () => {
      const ok = await copyText(this.resultText(r));
      this.toast(ok ? tr.copied : tr.copyFail);
    });
    host.querySelector('#r-share')?.addEventListener('click', async () => {
      const ok = await shareText(this.resultText(r));
      if (!ok) { await copyText(this.resultText(r)); this.toast(tr.sharedTip); }
    });
    host.querySelector('#r-fav')?.addEventListener('click', () => {
      const { fav: now } = toggleFav(r);
      this.haptic();
      this.toast(now ? tr.starred : tr.unstarred);
      this.renderResult(r);
    });
    host.querySelector('#r-amap')?.addEventListener('click', () =>
      window.open(`https://uri.amap.com/marker?position=${r.lon},${r.lat}&name=${encodeURIComponent(r.ip)}&src=ipgeo`, '_blank'));
    host.querySelector('#r-g')?.addEventListener('click', () =>
      window.open(`https://www.google.com/maps?q=${r.lat},${r.lon}`, '_blank'));
  }

  private resultText(r: IpResult): string {
    const tr = this.tr;
    return [
      `IP: ${r.ip}`,
      `${tr.fieldLocation}: ${locationText(r) || (r.isPrivate ? tr.noGeo : tr.unknown)}`,
      r.isp && `${tr.fieldIsp}: ${r.isp}`,
      r.asn && `${tr.fieldAsn}: ${r.asn}`,
      r.lat != null && r.lon != null && `${tr.fieldCoords}: ${r.lat}, ${r.lon}`,
      r.timezone && `${tr.fieldTimezone}: ${r.timezone}`,
      `${tr.fieldSource}: ${r.source}`,
      '—— IP·GEO',
    ].filter(Boolean).join('\n');
  }

  /* ================= Tab：批量 ================= */

  private renderBatchTab(main: HTMLElement): void {
    main.innerHTML = `
      <section class="panel">
        <textarea id="b-input" class="batch-area mono" placeholder="8.8.8.8&#10;qq.com&#10;114.114.114.114"></textarea>
        <div class="hint">${this.esc(this.tr.batchHint)}</div>
        <div class="search-row batch-actions">
          <button id="b-btn" class="btn-primary" style="flex:1">${this.esc(this.tr.batchStart)}</button>
          <button id="b-clear" class="act">${this.esc(this.tr.clear)}</button>
        </div>
        <div class="progress" id="b-prog" style="display:none"><div class="bar" id="b-bar"></div></div>
      </section>
      <div class="list-head">
        <span class="list-title mono" id="b-count">${this.batch.length} / ${this.batchTotal}</span>
        <span class="grow"></span>
        <button class="act" id="b-export" style="display:${this.batch.length ? '' : 'none'}">⧉ ${this.esc(this.tr.copyAll)}</button>
      </div>
      <section class="panel" id="b-list"></section>
    `;
    main.querySelector('#b-btn')!.addEventListener('click', () => void this.onBatch());
    main.querySelector('#b-clear')!.addEventListener('click', () => {
      (document.getElementById('b-input') as HTMLTextAreaElement).value = '';
      this.batch = [];
      this.batchTotal = 0;
      this.batchDone = 0;
      this.renderTab();
    });
    main.querySelector('#b-export')!.addEventListener('click', async () => {
      const text = this.batch
        .map((r) => `${r.ip}\t${locationText(r) || (r.isPrivate ? this.tr.privateTag : this.tr.lookupFail)}`)
        .join('\n');
      const ok = await copyText(text);
      this.toast(ok ? this.tr.copied : this.tr.copyFail);
    });
    this.renderBatchList();
  }

  private async onBatch(): Promise<void> {
    const input = document.getElementById('b-input') as HTMLTextAreaElement | null;
    if (!input) return;
    const lines = input.value.split(/\n+/).map((s) => s.trim()).filter(Boolean);
    if (!lines.length) { this.toast(this.tr.batchEmpty); return; }
    if (lines.length > 200) { this.toast(this.tr.batchMax); return; }
    this.haptic();
    this.batch = [];
    this.batchTotal = lines.length;
    this.batchDone = 0;
    const prog = document.getElementById('b-prog')!;
    const bar = document.getElementById('b-bar') as HTMLElement;
    prog.style.display = 'block';
    bar.style.width = '0%';

    // 3 并发依次查询，兼顾速度与接口压力（遵循当前选中的数据源）
    const queue = [...lines];
    const worker = async (): Promise<void> => {
      while (queue.length) {
        const line = queue.shift()!;
        let r: IpResult | null = null;
        try {
          const target = parseQueryTarget(line);
          if (target.kind === 'invalid') {
            r = { ip: line, country: this.tr.fmtError, source: '-', time: Date.now() };
          } else if (target.kind === 'private') {
            r = { ip: target.value, country: this.tr.privateNet, isPrivate: true, privateType: target.type, source: 'Local', time: Date.now() };
          } else {
            const ip = target.kind === 'domain' ? await resolveDomain(target.value) : target.value;
            r = await queryIp(ip, this.settings.source);
          }
        } catch {
          r = { ip: line, country: this.tr.lookupFail, source: '-', time: Date.now() };
        }
        this.batch.push(r);
        this.batchDone++;
        bar.style.width = `${Math.round((this.batchDone / this.batchTotal) * 100)}%`;
        this.renderBatchList();
      }
    };
    await Promise.all([worker(), worker(), worker()]);
    prog.style.display = 'none';
    this.toast(`${this.tr.batchDone} · ${this.batchTotal}`);
  }

  private renderBatchList(): void {
    const list = document.getElementById('b-list');
    if (!list) return;
    const count = document.getElementById('b-count');
    if (count) count.textContent = `${this.batch.length} / ${this.batchTotal}`;
    const exportBtn = document.getElementById('b-export');
    if (exportBtn) exportBtn.style.display = this.batch.length ? '' : 'none';
    list.innerHTML = this.batch.length
      ? this.batch.map((r) => `
        <div class="rec" data-ip="${this.esc(r.ip)}">
          <div class="rec-main">
            <div class="rec-ip">${r.isPrivate ? '⌂' : flagEmoji(r.countryCode)} ${this.esc(r.ip)}</div>
            <div class="rec-sub">${this.esc(locationText(r) || '—')}</div>
          </div>
          <span class="rec-time">${this.esc(r.isp ?? r.source ?? '')}</span>
        </div>`).join('')
      : `<div class="empty"><div class="glyph">☰</div>${this.esc(this.tr.batchEmpty)}</div>`;
    list.querySelectorAll('.rec').forEach((it) =>
      it.addEventListener('click', () => this.gotoQuery((it as HTMLElement).dataset.ip!)));
  }

  /* ================= Tab：历史 ================= */

  private renderHistoryTab(main: HTMLElement): void {
    const h = getHistory();
    main.innerHTML = `
      <div class="list-head">
        <span class="list-title">${this.esc(this.tr.historyTitle)}</span>
        <span class="list-sub">${h.length} ${this.esc(this.tr.historyCap)}</span>
        <span class="grow"></span>
        ${h.length ? `<button class="act" id="h-clear">${this.esc(this.tr.clear)}</button>` : ''}
      </div>
      <section class="panel" id="h-list"></section>
    `;
    const list = main.querySelector('#h-list') as HTMLElement;
    if (!h.length) {
      list.innerHTML = `<div class="empty"><div class="glyph">◷</div>${this.esc(this.tr.emptyHistory)}</div>`;
    } else {
      list.innerHTML = h.map((it) => this.recHtml(it)).join('');
      this.bindRecList(list, removeHistory);
    }
    main.querySelector('#h-clear')?.addEventListener('click', () => {
      clearHistory();
      this.toast(this.tr.cleared);
      this.renderTab();
    });
  }

  /* ================= Tab：收藏 ================= */

  private renderFavsTab(main: HTMLElement): void {
    const favs = getFavs();
    main.innerHTML = `
      <div class="list-head">
        <span class="list-title">${this.esc(this.tr.favTitle)}</span>
        <span class="list-sub">${favs.length}</span>
        <span class="grow"></span>
        ${favs.length ? `<button class="act" id="f-clear">${this.esc(this.tr.clear)}</button>` : ''}
      </div>
      <section class="panel" id="f-list"></section>
    `;
    const list = main.querySelector('#f-list') as HTMLElement;
    if (!favs.length) {
      list.innerHTML = `<div class="empty"><div class="glyph">★</div>${this.esc(this.tr.emptyFav)}<br>${this.esc(this.tr.emptyFavSub)}</div>`;
    } else {
      list.innerHTML = favs.map((it) => this.recHtml(it)).join('');
      this.bindRecList(list, removeFav);
    }
    main.querySelector('#f-clear')?.addEventListener('click', () => {
      clearFavs();
      this.toast(this.tr.cleared);
      this.renderTab();
    });
  }

  private recHtml(it: RecordItem): string {
    const r = it.result;
    return `
      <div class="rec" data-ip="${this.esc(r.ip)}">
        <div class="rec-main">
          <div class="rec-ip">${r.isPrivate ? '⌂' : flagEmoji(r.countryCode)} ${this.esc(r.ip)}</div>
          <div class="rec-sub">${this.esc(locationText(r) || (r.isPrivate ? (r.privateType ?? this.tr.privateNet) : this.tr.unknown))}</div>
        </div>
        <span class="rec-time">${fmtTime(r.time)}</span>
        <button class="rec-del" data-del="${this.esc(r.ip)}">✕</button>
      </div>`;
  }

  /** 绑定记录列表：点行→查详情，点删除→移除 */
  private bindRecList(list: HTMLElement, removeFn: (ip: string) => RecordItem[]): void {
    list.querySelectorAll('.rec-del').forEach((b) =>
      b.addEventListener('click', (e) => {
        e.stopPropagation();
        removeFn((b as HTMLElement).dataset.del!);
        this.toast(this.tr.deleted);
        this.renderTab();
      }));
    list.querySelectorAll('.rec').forEach((it) =>
      it.addEventListener('click', () => this.gotoQuery((it as HTMLElement).dataset.ip!)));
  }

  /* ================= Tab：设置 ================= */

  private renderSettingsTab(main: HTMLElement): void {
    const tr = this.tr;
    main.innerHTML = `
      <div class="list-head"><span class="list-title">${this.esc(tr.tabSettings)}</span></div>
      <section class="panel">
        <div class="set-row">
          <div class="set-main"><div class="set-label">${this.esc(tr.language)}</div></div>
          <div class="seg-sm" id="s-lang">
            <button data-v="zh" class="${this.settings.lang === 'zh' ? 'on' : ''}">中文</button>
            <button data-v="en" class="${this.settings.lang === 'en' ? 'on' : ''}">EN</button>
          </div>
        </div>
        <div class="set-row">
          <div class="set-main"><div class="set-label">${this.esc(tr.appearance)}</div></div>
          <div class="seg-sm" id="s-theme">
            <button data-v="auto" class="${this.settings.theme === 'auto' ? 'on' : ''}">${this.esc(tr.themeAuto)}</button>
            <button data-v="light" class="${this.settings.theme === 'light' ? 'on' : ''}">${this.esc(tr.themeLight)}</button>
            <button data-v="dark" class="${this.settings.theme === 'dark' ? 'on' : ''}">${this.esc(tr.themeDark)}</button>
          </div>
        </div>
        <div class="set-row">
          <div class="set-main"><div class="set-label">${this.esc(tr.haptics)}</div><div class="set-sub">${this.esc(tr.hapticsSub)}</div></div>
          <button class="toggle ${this.settings.haptics ? 'on' : ''}" id="s-haptics"></button>
        </div>
        <div class="set-row">
          <div class="set-main"><div class="set-label">${this.esc(tr.dataMgmt)}</div><div class="set-sub">${this.esc(tr.dataSub)}</div></div>
          <button class="act" id="s-clear">🗑 ${this.esc(tr.clearData)}</button>
        </div>
      </section>

      <div class="list-head">
        <span class="list-title">${this.esc(tr.sourcesTitle)}</span>
        <span class="list-sub">${this.esc(this.settings.source === 'auto'
          ? tr.auto
          : SOURCE_META.find((s) => s.id === this.settings.source)?.name ?? '')}</span>
      </div>
      <section class="panel">
        <div class="hint">${this.esc(tr.sourcesNote)}</div>
        <div class="set-row">
          <div class="set-main"><div class="set-label">${this.esc(tr.auto)}</div><div class="set-sub">${this.esc(tr.autoSub)}</div></div>
          ${this.settings.source === 'auto' ? `<span class="badge">${this.esc(tr.current)}</span>` : ''}
        </div>
        ${SOURCE_META.map((s) => `
          <div class="set-row">
            <div class="set-main"><div class="set-label">${s.name}</div><div class="set-sub">${this.esc(tr[SRC_KEY[s.id]])}</div></div>
            ${this.settings.source === s.id ? `<span class="badge">${this.esc(tr.current)}</span>` : ''}
          </div>`).join('')}
      </section>
      <div class="about">${this.esc(tr.about)}</div>
    `;
    main.querySelectorAll('#s-lang button').forEach((b) =>
      b.addEventListener('click', () => {
        this.settings.lang = (b as HTMLElement).dataset.v as AppSettings['lang'];
        saveSettings(this.settings);
        this.haptic();
        this.render();
      }));
    main.querySelectorAll('#s-theme button').forEach((b) =>
      b.addEventListener('click', () => {
        this.settings.theme = (b as HTMLElement).dataset.v as AppSettings['theme'];
        saveSettings(this.settings);
        this.applyTheme();
        this.haptic();
        this.renderHeader();
        this.renderTab();
      }));
    main.querySelector('#s-haptics')!.addEventListener('click', () => {
      this.settings.haptics = !this.settings.haptics;
      saveSettings(this.settings);
      this.haptic();
      this.renderTab();
    });
    main.querySelector('#s-clear')!.addEventListener('click', () => {
      clearHistory();
      clearFavs();
      this.result = null;
      this.toast(this.tr.cleared);
      this.renderTab();
    });
  }
}
