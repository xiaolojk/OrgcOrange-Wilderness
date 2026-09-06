/* ================= 类型定义 ================= */

/** 统一的 IP 查询结果模型 */
export interface IpResult {
  ip: string;
  country: string;
  countryCode?: string;   // ISO 两位国家码，用于国旗 emoji
  region?: string;        // 省 / 州
  city?: string;          // 市
  district?: string;      // 区县（部分源有）
  isp?: string;           // 运营商
  asn?: string;           // AS 号，如 AS4134
  org?: string;           // 组织名
  lat?: number;
  lon?: number;
  timezone?: string;
  zipcode?: string;
  source: string;         // 数据源名称
  isPrivate?: boolean;    // 内网 / 保留地址
  privateType?: string;   // 内网类型说明
  time: number;           // 查询时间戳
}

/** 历史/收藏条目 */
export interface RecordItem {
  result: IpResult;
  favTime?: number;
}

export type ThemeMode = 'auto' | 'light' | 'dark';

export interface AppSettings {
  theme: ThemeMode;
  haptics: boolean;       // 震动反馈
  autoQueryOnPaste?: boolean;
}

/** 查询目标解析结果 */
export type QueryTarget =
  | { kind: 'ipv4'; value: string }
  | { kind: 'ipv6'; value: string }
  | { kind: 'domain'; value: string }
  | { kind: 'private'; value: string; type: string }
  | { kind: 'invalid'; value: string };
