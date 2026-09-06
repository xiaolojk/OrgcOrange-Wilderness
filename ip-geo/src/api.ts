import type { IpResult, QuerySource, SourceId } from './types';
import { countryNameZh } from './ipUtils';

/* ================= 多数据源 IP 归属地查询（用户可选源 / 自动容错） ================= */

/** 带超时的 fetch（Capacitor 原生运行时下走 CapacitorHttp，无 CORS 限制） */
async function fetchJSON(url: string, timeoutMs = 6000): Promise<any> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: ctrl.signal });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } finally {
    clearTimeout(timer);
  }
}

/** 清洗字段：去掉空值 / 占位符 */
function clean(s?: string | null): string | undefined {
  if (s == null) return undefined;
  const t = String(s).trim();
  return t && t !== 'N/A' && t !== 'null' && t !== 'undefined' ? t : undefined;
}

/** 数据源定义（全部 UTF-8 编码，避免中文乱码） */
interface Source {
  id: SourceId;
  name: string;
  query: (ip: string) => Promise<IpResult>;
}

const SOURCES: Source[] = [
  {
    // vore.top（国内、HTTPS、UTF-8 中文、含运营商）
    id: 'vore',
    name: 'vore.top',
    async query(ip) {
      const d = await fetchJSON(`https://api.vore.top/api/IPdata?ip=${encodeURIComponent(ip)}`);
      if (d.code !== 200 || !d.ipdata) throw new Error(d.msg || '查询失败');
      const info1 = clean(d.ipdata.info1);
      const info2 = clean(d.ipdata.info2);
      const info3 = clean(d.ipdata.info3);
      const isp = clean(d.ipdata.isp);
      const isCn = d.ipinfo?.cnip === true;
      return {
        ip,
        country: isCn ? '中国' : (info1 ?? '未知'),
        region: isCn ? info1 : info2,
        city: isCn ? info2 : info3,
        district: isCn ? info3 : undefined,
        isp,
        source: this.name,
        time: Date.now(),
      };
    },
  },
  {
    // ip-api.com（国际、UTF-8 中文输出、字段全）
    id: 'ipapi',
    name: 'ip-api.com',
    async query(ip) {
      const d = await fetchJSON(
        `http://ip-api.com/json/${encodeURIComponent(ip)}?lang=zh-CN&fields=status,message,country,countryCode,regionName,city,district,isp,org,as,lat,lon,timezone,zip`
      );
      if (d.status !== 'success') throw new Error(d.message || '查询失败');
      return {
        ip,
        country: clean(d.country) ?? '未知',
        countryCode: clean(d.countryCode),
        region: clean(d.regionName),
        city: clean(d.city),
        district: clean(d.district),
        isp: clean(d.isp),
        asn: clean(d.as)?.split(' ')[0],
        org: clean(d.org),
        lat: typeof d.lat === 'number' ? d.lat : undefined,
        lon: typeof d.lon === 'number' ? d.lon : undefined,
        timezone: clean(d.timezone),
        zipcode: clean(d.zip),
        source: this.name,
        time: Date.now(),
      };
    },
  },
  {
    // ipwho.is（国际、HTTPS、CORS 友好，经纬度/ASN 全）
    id: 'ipwho',
    name: 'ipwho.is',
    async query(ip) {
      const d = await fetchJSON(`https://ipwho.is/${encodeURIComponent(ip)}`);
      if (d.success === false) throw new Error(d.message || '查询失败');
      return {
        ip,
        country: countryNameZh(d.country_code, clean(d.country) ?? ''),
        countryCode: clean(d.country_code),
        region: clean(d.region),
        city: clean(d.city),
        isp: clean(d.connection?.isp) ?? clean(d.connection?.org),
        asn: clean(d.connection?.asn) ? `AS${d.connection.asn}` : undefined,
        org: clean(d.connection?.org),
        lat: typeof d.latitude === 'number' ? d.latitude : undefined,
        lon: typeof d.longitude === 'number' ? d.longitude : undefined,
        timezone: clean(d.timezone?.id) ?? clean(d.timezone?.utc),
        zipcode: clean(d.postal),
        source: this.name,
        time: Date.now(),
      };
    },
  },
  {
    // ipapi.co（国际兜底，UTF-8）
    id: 'ipapico',
    name: 'ipapi.co',
    async query(ip) {
      const d = await fetchJSON(`https://ipapi.co/${encodeURIComponent(ip)}/json/`);
      if (d.error) throw new Error(d.reason || '查询失败');
      return {
        ip,
        country: countryNameZh(d.country_code, clean(d.country_name) ?? ''),
        countryCode: clean(d.country_code),
        region: clean(d.region),
        city: clean(d.city),
        isp: clean(d.org),
        asn: clean(d.asn),
        lat: typeof d.latitude === 'number' ? d.latitude : undefined,
        lon: typeof d.longitude === 'number' ? d.longitude : undefined,
        timezone: clean(d.timezone),
        zipcode: clean(d.postal),
        source: this.name,
        time: Date.now(),
      };
    },
  },
];

/** 供 UI 渲染的源元数据 */
export const SOURCE_META: ReadonlyArray<{ id: SourceId; name: string }> =
  SOURCES.map((s) => ({ id: s.id, name: s.name }));

/**
 * 查询 IP 归属地
 * @param source 'auto' 走容错链；指定源 id 则只用该源查询
 */
export async function queryIp(ip: string, source: QuerySource = 'auto'): Promise<IpResult> {
  if (source !== 'auto') {
    const src = SOURCES.find((s) => s.id === source);
    if (src) return src.query(ip);
  }
  let lastErr: unknown = null;
  for (const src of SOURCES) {
    try {
      return await src.query(ip);
    } catch (e) {
      lastErr = e;
    }
  }
  throw new Error(`所有数据源均查询失败：${lastErr instanceof Error ? lastErr.message : '网络异常'}`);
}

/** 查询本机公网 IP（纯 IP 探测源） */
const MY_IP_SOURCES: Array<() => Promise<string>> = [
  async () => String((await fetchJSON('https://ipwho.is/')).ip ?? '').trim(),
  async () => String((await fetchJSON('https://api.ipify.org?format=json')).ip ?? '').trim(),
  async () => String((await fetchJSON('https://ipapi.co/json/')).ip ?? '').trim(),
];

export async function getMyIp(): Promise<string> {
  let lastErr: unknown = null;
  for (const fn of MY_IP_SOURCES) {
    try {
      const ip = await fn();
      if (ip && (ip.includes('.') || ip.includes(':'))) return ip;
    } catch (e) {
      lastErr = e;
    }
  }
  throw new Error(`无法获取本机 IP：${lastErr instanceof Error ? lastErr.message : '网络异常'}`);
}

/** 域名 → IP（DNS over HTTPS，国内源优先，多服务商容错） */
export async function resolveDomain(domain: string): Promise<string> {
  const tries: Array<() => Promise<string>> = [
    async () => {
      // 阿里公共 DNS（国内快，CORS 友好）
      const d = await fetchJSON(`https://dns.alidns.com/resolve?name=${encodeURIComponent(domain)}&type=A`);
      const ans = (d.Answer ?? []).find((a: any) => a.type === 1);
      if (!ans) throw new Error('无 A 记录');
      return String(ans.data);
    },
    async () => {
      // 腾讯 DNSPod
      const res = await fetch(`https://doh.pub/dns-query?name=${encodeURIComponent(domain)}&type=A`, {
        headers: { accept: 'application/dns-json' },
      });
      const d = await res.json();
      const ans = (d.Answer ?? []).find((a: any) => a.type === 1);
      if (!ans) throw new Error('无 A 记录');
      return String(ans.data);
    },
    async () => {
      // Google DNS（海外网络）
      const d = await fetchJSON(`https://dns.google/resolve?name=${encodeURIComponent(domain)}&type=A`);
      const ans = (d.Answer ?? []).find((a: any) => a.type === 1);
      if (!ans) throw new Error('无 A 记录');
      return String(ans.data);
    },
    async () => {
      // Cloudflare DNS（海外网络）
      const res = await fetch(`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(domain)}&type=A`, {
        headers: { accept: 'application/dns-json' },
      });
      const d = await res.json();
      const ans = (d.Answer ?? []).find((a: any) => a.type === 1);
      if (!ans) throw new Error('无 A 记录');
      return String(ans.data);
    },
  ];
  let lastErr: unknown = null;
  for (const fn of tries) {
    try {
      return await fn();
    } catch (e) {
      lastErr = e;
    }
  }
  throw new Error(`域名解析失败：${lastErr instanceof Error ? lastErr.message : 'DNS 异常'}`);
}
