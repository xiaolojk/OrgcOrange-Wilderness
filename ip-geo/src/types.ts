/** 查询来源 */
export type ApiSource = 'auto' | 'ip-api' | 'ipwho';

/** 主题模式 */
export type ThemeMode = 'auto' | 'light' | 'dark';

/** 应用设置 */
export interface Settings {
  theme: ThemeMode;
  apiSource: ApiSource;
  historyLimit: number; // 0 = 不限制
  haptics: boolean;
}

/** 统一的 IP 查询结果 */
export interface IpResult {
  ip: string;
  /** 国家（中文） */
  country: string;
  countryCode: string;
  /** 国旗 emoji */
  flag: string;
  /** 省/州 */
  region: string;
  /** 城市 */
  city: string;
  /** 区县 */
  district?: string;
  /** 运营商 */
  isp: string;
  /** 组织 */
  org?: string;
  /** ASN，如 AS4134 */
  asn?: string;
  lat?: number;
  lon?: number;
  /** 时区，如 Asia/Shanghai */
  timezone?: string;
  /** UTC 偏移，如 +08:00 */
  utcOffset?: string;
  /** 邮编 */
  zip?: string;
  /** 是否移动网络 */
  isMobile?: boolean;
  /** 是否代理/VPN */
  isProxy?: boolean;
  /** 是否机房/托管 */
  isHosting?: boolean;
  /** 是否内网/保留地址（本地判断，不走 API） */
  isPrivate: boolean;
  /** 数据来源 */
  source: string;
  /** 查询时间戳 */
  ts: number;
  /** 域名解析注记（查域名时记录） */
  domainNote?: string;
  /** 查询失败时的错误信息 */
  error?: string;
}

/** 历史记录条目 */
export interface HistoryItem extends IpResult {
  /** 是否已收藏 */
  starred: boolean;
}

/** 输入解析结果 */
export interface ParsedInput {
  kind: 'ipv4' | 'ipv6' | 'domain' | 'invalid' | 'empty';
  value: string;
  message?: string;
}

export const DEFAULT_SETTINGS: Settings = {
  theme: 'auto',
  apiSource: 'auto',
  historyLimit: 100,
  haptics: true,
};
