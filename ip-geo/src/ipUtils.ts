import type { QueryTarget } from './types';

/* ================= IP / 域名工具 ================= */

/** 校验 IPv4 */
export function isIPv4(s: string): boolean {
  const m = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(s.trim());
  if (!m) return false;
  return m.slice(1).every((p) => {
    if (p.length > 1 && p[0] === '0') return false;
    const n = Number(p);
    return n >= 0 && n <= 255;
  });
}

/** 校验 IPv6（宽松校验） */
export function isIPv6(s: string): boolean {
  const t = s.trim();
  if (!t.includes(':')) return false;
  // 排除端口号误判（如 1.2.3.4:80）
  if (isIPv4(t.split(':')[0]) && t.split(':').length === 2) return false;
  return /^[0-9a-fA-F:]+$/.test(t) && (t.match(/::/g)?.length ?? 0) <= 1;
}

/** 合法域名 */
export function isDomain(s: string): boolean {
  const t = s.trim().toLowerCase().replace(/\.$/, '');
  if (t.length < 3 || t.length > 253) return false;
  if (isIPv4(t) || isIPv6(t)) return false;
  const re = /^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$/;
  return re.test(t);
}

/** 内网 / 保留地址段识别 */
export function getPrivateType(ip: string): string | null {
  if (isIPv4(ip)) {
    const [a, b] = ip.split('.').map(Number);
    if (a === 10) return '内网地址（10.0.0.0/8）';
    if (a === 172 && b >= 16 && b <= 31) return '内网地址（172.16.0.0/12）';
    if (a === 192 && b === 168) return '内网地址（192.168.0.0/16）';
    if (a === 127) return '回环地址（127.0.0.0/8）';
    if (a === 169 && b === 254) return '链路本地（169.254.0.0/16）';
    if (a === 0) return '本网络（0.0.0.0/8）';
    if (a === 100 && b >= 64 && b <= 127) return '运营商级 NAT（100.64.0.0/10）';
    if (a >= 224) return '组播 / 保留地址';
    return null;
  }
  if (isIPv6(ip)) {
    const t = ip.toLowerCase();
    if (t === '::1' || t === '::') return '回环 / 未指定地址';
    if (t.startsWith('fe80')) return '链路本地（fe80::/10）';
    if (t.startsWith('fc') || t.startsWith('fd')) return '唯一本地（fc00::/7）';
    return null;
  }
  return null;
}

/** 解析输入：IP / 域名 / 内网 */
export function parseQueryTarget(input: string): QueryTarget {
  const t = input.trim();
  if (!t) return { kind: 'invalid', value: '' };
  // 自动去掉 http(s):// 前缀和路径
  const stripped = t.replace(/^https?:\/\//i, '').replace(/\/.*$/, '').replace(/:\d+$/, '');
  if (isIPv4(stripped) || isIPv6(stripped)) {
    const pt = getPrivateType(stripped);
    if (pt) return { kind: 'private', value: stripped, type: pt };
    return { kind: isIPv4(stripped) ? 'ipv4' : 'ipv6', value: stripped };
  }
  if (isDomain(stripped)) return { kind: 'domain', value: stripped };
  return { kind: 'invalid', value: t };
}

/** 国家码 → 国旗 emoji */
export function flagEmoji(countryCode?: string): string {
  if (!countryCode || countryCode.length !== 2) return '🌐';
  const cc = countryCode.toUpperCase();
  return String.fromCodePoint(...[...cc].map((c) => 127397 + c.charCodeAt(0)));
}

/** ISO 国家码 → 中文名（常用部分，其余返回原名） */
const COUNTRY_ZH: Record<string, string> = {
  CN: '中国', HK: '中国香港', TW: '中国台湾', MO: '中国澳门',
  US: '美国', JP: '日本', KR: '韩国', SG: '新加坡', MY: '马来西亚',
  TH: '泰国', VN: '越南', PH: '菲律宾', ID: '印度尼西亚', IN: '印度',
  GB: '英国', DE: '德国', FR: '法国', IT: '意大利', ES: '西班牙',
  NL: '荷兰', BE: '比利时', CH: '瑞士', AT: '奥地利', SE: '瑞典',
  NO: '挪威', DK: '丹麦', FI: '芬兰', IE: '爱尔兰', PT: '葡萄牙',
  PL: '波兰', CZ: '捷克', RO: '罗马尼亚', RU: '俄罗斯', UA: '乌克兰',
  AU: '澳大利亚', NZ: '新西兰', CA: '加拿大', MX: '墨西哥', BR: '巴西',
  AR: '阿根廷', CL: '智利', ZA: '南非', EG: '埃及', NG: '尼日利亚',
  SA: '沙特阿拉伯', AE: '阿联酋', TR: '土耳其', IL: '以色列',
  IR: '伊朗', IQ: '伊拉克', PK: '巴基斯坦', BD: '孟加拉国', LK: '斯里兰卡',
  NP: '尼泊尔', MM: '缅甸', KH: '柬埔寨', LA: '老挝', MN: '蒙古',
  KZ: '哈萨克斯坦', UZ: '乌兹别克斯坦',
};

export function countryNameZh(code?: string, fallback = ''): string {
  if (!code) return fallback;
  return COUNTRY_ZH[code.toUpperCase()] ?? fallback;
}

/** 归属地一行拼接：国家 省 市 运营商 */
export function locationText(r: { country?: string; region?: string; city?: string; district?: string; isp?: string }): string {
  return [r.country, r.region, r.city, r.district, r.isp].filter(Boolean).join(' ');
}

/** 时间格式化 */
export function fmtTime(ts: number): string {
  const d = new Date(ts);
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

/** 剪贴板复制（降级方案） */
export async function copyText(text: string): Promise<boolean> {
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch { /* 忽略走降级 */ }
  try {
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    const ok = document.execCommand('copy');
    ta.remove();
    return ok;
  } catch {
    return false;
  }
}

/** 分享（Web Share API，Android WebView 支持） */
export async function shareText(text: string, title = 'IP 归属地查询结果'): Promise<boolean> {
  try {
    if (navigator.share) {
      await navigator.share({ title, text });
      return true;
    }
  } catch { /* 用户取消或失败 */ }
  return false;
}
