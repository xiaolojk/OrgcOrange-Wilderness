import type { IpResult } from './types';
import { countryNameZh } from './ipUtils';

/* ================= 多数据源 IP 归属地查询（自动容错） ================= */

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

/** 拼接归属地字段（处理部分源字符串里带空格的情况） */
function clean(s?: string | null): string | undefined {
  if (s == null) return undefined;
  const t = String(s).trim();
  return t && t !== 'N/A' && t !== 'null' && t !== 'undefined' ? t : undefined;
}

/** 各数据源的查询与解析逻辑 */
interface Source {
  name: string;
  query: (ip: string) => Promise<IpResult>;
}

const SOURCES: Source[] = [
  {
    // 太平洋电脑网（国内快、中文、含运营商）
    name: '太平洋网络',
    async query(ip) {
      const d = await fetchJSON(`https://whois.pconline.com.cn/ipJson.jsp?ip=${encodeURIComponent(ip)}&json=true`);
      const country = clean(d.country) ?? '';
      const region = clean(d.pro) ?? '';
      const city = clean(d.city) ?? '';
      const isp = clean(d.isp) ?? (clean(d.addr) ?? '').split(/\s+/).slice(-1)[0];
      if (!country && !region && !city) throw new Error('空结果');
      return {
        ip, country: country || '未知', region, city, isp,
        source: this.name, time: Date.now(),
      };
    },
  },
  {
    // ipwho.is（国际、HTTPS、CORS 友好，浏览器兜底首选）
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
    // ip-api.com（国际、中文输出）
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
    // 百度开放数据（国内）
    name: '百度开放数据',
    async query(ip) {
      const d = await fetchJSON(
        `https://opendata.baidu.com/api.php?query=${encodeURIComponent(ip)}&co=&resource_id=6006&format=json`
      );
      const loc = clean(d?.data?.[0]?.location);
      if (!loc) throw new Error('空结果');
      // location 形如 "中国广东深圳 电信"，切分运营商
      const m = /^(.*?)\s*((?:电信|联通|移动|铁通|鹏博士|长城|教育网|谷歌|微软|亚马逊|阿里云|腾讯云|华为云).*)?$/.exec(loc);
      const place = (m?.[1] ?? loc).trim();
      const isp = m?.[2]?.trim();
      return { ip, country: place, isp, source: this.name, time: Date.now() };
    },
  },
  {
    // useragentinfo（国内）
    name: 'UserAgentInfo',
    async query(ip) {
      const d = await fetchJSON(`https://ip.useragentinfo.com/json?ip=${encodeURIComponent(ip)}`);
      if (d.code !== 200 || !d.country) throw new Error('查询失败');
      return {
        ip,
        country: clean(d.country) ?? '未知',
        region: clean(d.province),
        city: clean(d.city),
        isp: clean(d.isp),
        source: this.name,
        time: Date.now(),
      };
    },
  },
  {
    // ipapi.co（国际兜底）
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

/** 依序尝试所有数据源，直到成功 */
export async function queryIp(ip: string): Promise<IpResult> {
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
  async () => (await (await fetch('https://api.ip.sb/ip')).text()).trim(),
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
