var D=Object.defineProperty;var j=(i,t,e)=>t in i?D(i,t,{enumerable:!0,configurable:!0,writable:!0,value:e}):i[t]=e;var u=(i,t,e)=>j(i,typeof t!="symbol"?t+"":t,e);(function(){const t=document.createElement("link").relList;if(t&&t.supports&&t.supports("modulepreload"))return;for(const n of document.querySelectorAll('link[rel="modulepreload"]'))s(n);new MutationObserver(n=>{for(const a of n)if(a.type==="childList")for(const o of a.addedNodes)o.tagName==="LINK"&&o.rel==="modulepreload"&&s(o)}).observe(document,{childList:!0,subtree:!0});function e(n){const a={};return n.integrity&&(a.integrity=n.integrity),n.referrerPolicy&&(a.referrerPolicy=n.referrerPolicy),n.crossOrigin==="use-credentials"?a.credentials="include":n.crossOrigin==="anonymous"?a.credentials="omit":a.credentials="same-origin",a}function s(n){if(n.ep)return;n.ep=!0;const a=e(n);fetch(n.href,a)}})();function b(i){const t=/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(i.trim());return t?t.slice(1).every(e=>{if(e.length>1&&e[0]==="0")return!1;const s=Number(e);return s>=0&&s<=255}):!1}function L(i){var e;const t=i.trim();return!t.includes(":")||b(t.split(":")[0])&&t.split(":").length===2?!1:/^[0-9a-fA-F:]+$/.test(t)&&(((e=t.match(/::/g))==null?void 0:e.length)??0)<=1}function U(i){const t=i.trim().toLowerCase().replace(/\.$/,"");return t.length<3||t.length>253||b(t)||L(t)?!1:/^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$/.test(t)}function O(i){if(b(i)){const[t,e]=i.split(".").map(Number);return t===10?"内网地址（10.0.0.0/8）":t===172&&e>=16&&e<=31?"内网地址（172.16.0.0/12）":t===192&&e===168?"内网地址（192.168.0.0/16）":t===127?"回环地址（127.0.0.0/8）":t===169&&e===254?"链路本地（169.254.0.0/16）":t===0?"本网络（0.0.0.0/8）":t===100&&e>=64&&e<=127?"运营商级 NAT（100.64.0.0/10）":t>=224?"组播 / 保留地址":null}if(L(i)){const t=i.toLowerCase();return t==="::1"||t==="::"?"回环 / 未指定地址":t.startsWith("fe80")?"链路本地（fe80::/10）":t.startsWith("fc")||t.startsWith("fd")?"唯一本地（fc00::/7）":null}return null}function B(i){const t=i.trim();if(!t)return{kind:"invalid",value:""};const e=t.replace(/^https?:\/\//i,"").replace(/\/.*$/,"").replace(/:\d+$/,"");if(b(e)||L(e)){const s=O(e);return s?{kind:"private",value:e,type:s}:{kind:b(e)?"ipv4":"ipv6",value:e}}return U(e)?{kind:"domain",value:e}:{kind:"invalid",value:t}}function I(i){if(!i||i.length!==2)return"🌐";const t=i.toUpperCase();return String.fromCodePoint(...[...t].map(e=>127397+e.charCodeAt(0)))}const _={CN:"中国",HK:"中国香港",TW:"中国台湾",MO:"中国澳门",US:"美国",JP:"日本",KR:"韩国",SG:"新加坡",MY:"马来西亚",TH:"泰国",VN:"越南",PH:"菲律宾",ID:"印度尼西亚",IN:"印度",GB:"英国",DE:"德国",FR:"法国",IT:"意大利",ES:"西班牙",NL:"荷兰",BE:"比利时",CH:"瑞士",AT:"奥地利",SE:"瑞典",NO:"挪威",DK:"丹麦",FI:"芬兰",IE:"爱尔兰",PT:"葡萄牙",PL:"波兰",CZ:"捷克",RO:"罗马尼亚",RU:"俄罗斯",UA:"乌克兰",AU:"澳大利亚",NZ:"新西兰",CA:"加拿大",MX:"墨西哥",BR:"巴西",AR:"阿根廷",CL:"智利",ZA:"南非",EG:"埃及",NG:"尼日利亚",SA:"沙特阿拉伯",AE:"阿联酋",TR:"土耳其",IL:"以色列",IR:"伊朗",IQ:"伊拉克",PK:"巴基斯坦",BD:"孟加拉国",LK:"斯里兰卡",NP:"尼泊尔",MM:"缅甸",KH:"柬埔寨",LA:"老挝",MN:"蒙古",KZ:"哈萨克斯坦",UZ:"乌兹别克斯坦"};function S(i,t=""){return i?_[i.toUpperCase()]??t:t}function m(i){return[i.country,i.region,i.city,i.district,i.isp].filter(Boolean).join(" ")}function P(i){const t=new Date(i),e=s=>String(s).padStart(2,"0");return`${t.getFullYear()}-${e(t.getMonth()+1)}-${e(t.getDate())} ${e(t.getHours())}:${e(t.getMinutes())}`}async function w(i){var t;try{if((t=navigator.clipboard)!=null&&t.writeText)return await navigator.clipboard.writeText(i),!0}catch{}try{const e=document.createElement("textarea");e.value=i,e.style.position="fixed",e.style.opacity="0",document.body.appendChild(e),e.select();const s=document.execCommand("copy");return e.remove(),s}catch{return!1}}async function F(i,t="IP 归属地查询结果"){try{if(navigator.share)return await navigator.share({title:t,text:i}),!0}catch{}return!1}async function p(i,t=6e3){const e=new AbortController,s=setTimeout(()=>e.abort(),t);try{const n=await fetch(i,{signal:e.signal});if(!n.ok)throw new Error(`HTTP ${n.status}`);return await n.json()}finally{clearTimeout(s)}}function r(i){if(i==null)return;const t=String(i).trim();return t&&t!=="N/A"&&t!=="null"&&t!=="undefined"?t:void 0}const Q=[{name:"vore.top",async query(i){var c;const t=await p(`https://api.vore.top/api/IPdata?ip=${encodeURIComponent(i)}`);if(t.code!==200||!t.ipdata)throw new Error(t.msg||"查询失败");const e=r(t.ipdata.info1),s=r(t.ipdata.info2),n=r(t.ipdata.info3),a=r(t.ipdata.isp),o=((c=t.ipinfo)==null?void 0:c.cnip)===!0;return{ip:i,country:o?"中国":e??"未知",region:o?e:s,city:o?s:n,district:o?n:void 0,isp:a,source:this.name,time:Date.now()}}},{name:"ip-api.com",async query(i){var e;const t=await p(`http://ip-api.com/json/${encodeURIComponent(i)}?lang=zh-CN&fields=status,message,country,countryCode,regionName,city,district,isp,org,as,lat,lon,timezone,zip`);if(t.status!=="success")throw new Error(t.message||"查询失败");return{ip:i,country:r(t.country)??"未知",countryCode:r(t.countryCode),region:r(t.regionName),city:r(t.city),district:r(t.district),isp:r(t.isp),asn:(e=r(t.as))==null?void 0:e.split(" ")[0],org:r(t.org),lat:typeof t.lat=="number"?t.lat:void 0,lon:typeof t.lon=="number"?t.lon:void 0,timezone:r(t.timezone),zipcode:r(t.zip),source:this.name,time:Date.now()}}},{name:"ipwho.is",async query(i){var e,s,n,a,o,c;const t=await p(`https://ipwho.is/${encodeURIComponent(i)}`);if(t.success===!1)throw new Error(t.message||"查询失败");return{ip:i,country:S(t.country_code,r(t.country)??""),countryCode:r(t.country_code),region:r(t.region),city:r(t.city),isp:r((e=t.connection)==null?void 0:e.isp)??r((s=t.connection)==null?void 0:s.org),asn:r((n=t.connection)==null?void 0:n.asn)?`AS${t.connection.asn}`:void 0,org:r((a=t.connection)==null?void 0:a.org),lat:typeof t.latitude=="number"?t.latitude:void 0,lon:typeof t.longitude=="number"?t.longitude:void 0,timezone:r((o=t.timezone)==null?void 0:o.id)??r((c=t.timezone)==null?void 0:c.utc),zipcode:r(t.postal),source:this.name,time:Date.now()}}},{name:"ipapi.co",async query(i){const t=await p(`https://ipapi.co/${encodeURIComponent(i)}/json/`);if(t.error)throw new Error(t.reason||"查询失败");return{ip:i,country:S(t.country_code,r(t.country_name)??""),countryCode:r(t.country_code),region:r(t.region),city:r(t.city),isp:r(t.org),asn:r(t.asn),lat:typeof t.latitude=="number"?t.latitude:void 0,lon:typeof t.longitude=="number"?t.longitude:void 0,timezone:r(t.timezone),zipcode:r(t.postal),source:this.name,time:Date.now()}}}];async function R(i){let t=null;for(const e of Q)try{return await e.query(i)}catch(s){t=s}throw new Error(`所有数据源均查询失败：${t instanceof Error?t.message:"网络异常"}`)}const K=[async()=>String((await p("https://ipwho.is/")).ip??"").trim(),async()=>String((await p("https://api.ipify.org?format=json")).ip??"").trim(),async()=>String((await p("https://ipapi.co/json/")).ip??"").trim()];async function G(){let i=null;for(const t of K)try{const e=await t();if(e&&(e.includes(".")||e.includes(":")))return e}catch(e){i=e}throw new Error(`无法获取本机 IP：${i instanceof Error?i.message:"网络异常"}`)}async function A(i){const t=[async()=>{const n=((await p(`https://dns.alidns.com/resolve?name=${encodeURIComponent(i)}&type=A`)).Answer??[]).find(a=>a.type===1);if(!n)throw new Error("无 A 记录");return String(n.data)},async()=>{const a=((await(await fetch(`https://doh.pub/dns-query?name=${encodeURIComponent(i)}&type=A`,{headers:{accept:"application/dns-json"}})).json()).Answer??[]).find(o=>o.type===1);if(!a)throw new Error("无 A 记录");return String(a.data)},async()=>{const n=((await p(`https://dns.google/resolve?name=${encodeURIComponent(i)}&type=A`)).Answer??[]).find(a=>a.type===1);if(!n)throw new Error("无 A 记录");return String(n.data)},async()=>{const a=((await(await fetch(`https://cloudflare-dns.com/dns-query?name=${encodeURIComponent(i)}&type=A`,{headers:{accept:"application/dns-json"}})).json()).Answer??[]).find(o=>o.type===1);if(!a)throw new Error("无 A 记录");return String(a.data)}];let e=null;for(const s of t)try{return await s()}catch(n){e=n}throw new Error(`域名解析失败：${e instanceof Error?e.message:"DNS 异常"}`)}const E="ipgeo.history.v1",f="ipgeo.favs.v1",N="ipgeo.settings.v1",C=100;function k(i,t){try{const e=localStorage.getItem(i);return e?JSON.parse(e):t}catch{return t}}function v(i,t){try{localStorage.setItem(i,JSON.stringify(t))}catch{}}function y(){return k(E,[])}function q(i){const t=y().filter(e=>e.result.ip!==i.ip);return t.unshift({result:i}),t.length>C&&(t.length=C),v(E,t),t}function Z(i){const t=y().filter(e=>e.result.ip!==i);return v(E,t),t}function H(){v(E,[])}function T(){return k(f,[])}function Y(i){return T().some(t=>t.result.ip===i)}function J(i){const t=T(),e=t.findIndex(s=>s.result.ip===i.ip);return e>=0?(t.splice(e,1),v(f,t),{favs:t,fav:!1}):(t.unshift({result:i,favTime:Date.now()}),v(f,t),{favs:t,fav:!0})}function W(i){const t=T().filter(e=>e.result.ip!==i);return v(f,t),t}function x(){v(f,[])}const V={theme:"auto",haptics:!0};function X(){return{...V,...k(N,{})}}function M(i){v(N,i)}const tt=[{id:"query",icon:"🔍",label:"查询"},{id:"batch",icon:"📚",label:"批量"},{id:"history",icon:"🕘",label:"历史"},{id:"favs",icon:"⭐",label:"收藏"},{id:"settings",icon:"⚙️",label:"设置"}];class z{constructor(t){u(this,"root");u(this,"settings");u(this,"currentTab","query");u(this,"currentResult",null);u(this,"loading",!1);u(this,"batchResults",[]);u(this,"batchTotal",0);u(this,"batchDone",0);this.root=t,this.settings=X(),this.applyTheme(),this.render()}applyTheme(){const t=this.settings.theme,e=t==="dark"||t==="auto"&&window.matchMedia("(prefers-color-scheme: dark)").matches;document.documentElement.dataset.theme=e?"dark":"light";const s=document.querySelector('meta[name="theme-color"]');s&&s.setAttribute("content",e?"#0f1420":"#2563eb")}toast(t){const e=document.createElement("div");e.className="toast",e.textContent=t,document.body.appendChild(e),setTimeout(()=>e.remove(),1900)}haptic(){var t;if(this.settings.haptics)try{(t=navigator.vibrate)==null||t.call(navigator,12)}catch{}}esc(t){return String(t??"").replace(/[&<>"']/g,e=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"})[e])}render(){this.root.innerHTML=`
      <header class="app-header">
        <div class="logo">🌐</div>
        <h1>IP 归属地查询</h1>
        <button class="header-btn" id="btn-myip">📍 我的IP</button>
      </header>
      <main id="tab-content"></main>
      <nav class="tabbar"><div class="tabbar-inner" id="tabbar"></div></nav>
    `,this.renderTabbar(),this.renderTab(),document.getElementById("btn-myip").addEventListener("click",()=>this.onMyIp())}renderTabbar(){const t=document.getElementById("tabbar");t.innerHTML=tt.map(e=>`<button class="tab-item ${e.id===this.currentTab?"on":""}" data-tab="${e.id}">
        <span class="icon">${e.icon}</span><span>${e.label}</span></button>`).join(""),t.querySelectorAll(".tab-item").forEach(e=>e.addEventListener("click",()=>{this.currentTab=e.dataset.tab,this.haptic(),this.renderTabbar(),this.renderTab()}))}renderTab(){const t=document.getElementById("tab-content");switch(this.currentTab){case"query":this.renderQueryTab(t);break;case"batch":this.renderBatchTab(t);break;case"history":this.renderHistoryTab(t);break;case"favs":this.renderFavsTab(t);break;case"settings":this.renderSettingsTab(t);break}}renderQueryTab(t){const e=y().slice(0,6);t.innerHTML=`
      <div class="search-box">
        <div class="search-row">
          <input class="search-input" id="q-input" placeholder="输入 IP 地址或域名，如 8.8.8.8 / baidu.com"
            autocomplete="off" autocapitalize="off" spellcheck="false">
          <button class="btn btn-primary" id="q-btn">查询</button>
        </div>
        <div class="search-tips" id="q-tips">
          ${e.map(n=>`<span class="tip-chip" data-ip="${this.esc(n.result.ip)}">${this.esc(n.result.ip)}</span>`).join("")}
        </div>
      </div>
      <div id="q-status"></div>
    `;const s=document.getElementById("q-input");s.addEventListener("keydown",n=>{n.key==="Enter"&&this.onQuery(s.value)}),document.getElementById("q-btn").addEventListener("click",()=>this.onQuery(s.value)),document.getElementById("q-tips").querySelectorAll(".tip-chip").forEach(n=>n.addEventListener("click",()=>{s.value=n.dataset.ip,this.onQuery(s.value)})),this.currentResult&&this.renderResult(this.currentResult)}async onQuery(t){const e=B(t);if(e.kind==="invalid"){this.toast("❌ 请输入合法的 IP 或域名");return}const s=document.getElementById("q-status");if(this.haptic(),this.loading=!0,e.kind==="private"){this.currentResult={ip:e.value,country:"局域网 / 保留地址",isPrivate:!0,privateType:e.type,source:"本地识别",time:Date.now()},q(this.currentResult),this.loading=!1,this.renderResult(this.currentResult),this.refreshTipChips();return}s.innerHTML=`<div class="loading-box"><div class="spinner"></div>
      ${e.kind==="domain"?`正在解析域名 ${this.esc(e.value)} …`:"正在查询，稍候…"}</div>`;try{let n=e.value;e.kind==="domain"&&(s.innerHTML=`<div class="loading-box"><div class="spinner"></div>正在解析域名 ${this.esc(e.value)} …</div>`,n=await A(e.value)),s.innerHTML=`<div class="loading-box"><div class="spinner"></div>正在查询 ${this.esc(n)} 的归属地…</div>`;const a=await R(n);this.currentResult=a,q(a),s.innerHTML="",this.renderResult(a),this.refreshTipChips()}catch(n){s.innerHTML=`<div class="error-box">❌ ${this.esc(n instanceof Error?n.message:"查询失败，请检查网络")}</div>`}finally{this.loading=!1}}async onMyIp(){const t=document.getElementById("btn-myip");t.disabled=!0,this.haptic();try{const e=await G();this.currentTab="query",this.renderTabbar(),this.renderTab();const s=document.getElementById("q-input");s&&(s.value=e),await this.onQuery(e)}catch(e){this.toast(`❌ ${e instanceof Error?e.message:"获取失败"}`)}finally{t.disabled=!1}}refreshTipChips(){const t=document.getElementById("q-tips");if(!t)return;const e=y().slice(0,6);t.innerHTML=e.map(s=>`<span class="tip-chip" data-ip="${this.esc(s.result.ip)}">${this.esc(s.result.ip)}</span>`).join(""),t.querySelectorAll(".tip-chip").forEach(s=>s.addEventListener("click",()=>{const n=document.getElementById("q-input");n.value=s.dataset.ip,this.onQuery(n.value)}))}renderResult(t){var a,o,c,h,l;const e=document.getElementById("q-status")??document.getElementById("tab-content"),s=Y(t.ip),n=[["归属地",m(t)||"未知"],["国家/地区",t.country],["省 / 州",t.region],["城市",t.city],["区县",t.district],["运营商",t.isp],["ASN",t.asn],["组织",t.org],["经纬度",t.lat!=null&&t.lon!=null?`${t.lat}, ${t.lon}`:void 0],["时区",t.timezone],["邮编",t.zipcode],["数据源",t.source],["查询时间",P(t.time)]];t.isPrivate&&n.unshift(["地址类型",t.privateType??"内网地址"]),e.innerHTML=`
      <div class="result-card">
        <div class="result-head">
          <div class="result-flag">${t.isPrivate?"🏠":I(t.countryCode)}</div>
          <div class="result-ip-block">
            <div class="result-ip">${this.esc(t.ip)}</div>
            <div class="result-loc">${this.esc(m(t)||(t.isPrivate?"局域网地址，无公网归属地":"未知"))}</div>
          </div>
          <span class="result-badge ${t.isPrivate?"private":""}">${t.isPrivate?"内网":t.countryCode?this.esc(t.countryCode):"IP"}</span>
        </div>
        <div class="detail-list">
          ${n.filter(([,d])=>d!=null&&d!=="").map(([d,g])=>`
            <div class="detail-row">
              <div class="detail-label">${d}</div>
              <div class="detail-value"><span>${this.esc(g)}</span>
                <span class="copy-icon" data-copy="${this.esc(g)}" title="复制">📋</span>
              </div>
            </div>`).join("")}
        </div>
        <div class="result-actions">
          <button class="btn-mini" id="r-copy">📋 复制结果</button>
          <button class="btn-mini" id="r-share">📤 分享</button>
          <button class="btn-mini ${s?"warn":""}" id="r-fav">${s?"⭐ 已收藏":"☆ 收藏"}</button>
          ${t.lat!=null&&t.lon!=null?`
            <button class="btn-mini" id="r-map-amap">🗺️ 高德地图</button>
            <button class="btn-mini" id="r-map-g">🌍 Google 地图</button>`:""}
        </div>
      </div>`,e.querySelectorAll(".copy-icon").forEach(d=>d.addEventListener("click",async()=>{const g=await w(d.dataset.copy);this.toast(g?"✅ 已复制":"❌ 复制失败")})),(a=document.getElementById("r-copy"))==null||a.addEventListener("click",async()=>{const d=await w(this.resultText(t));this.toast(d?"✅ 已复制结果":"❌ 复制失败")}),(o=document.getElementById("r-share"))==null||o.addEventListener("click",async()=>{await F(this.resultText(t))||(await w(this.resultText(t)),this.toast("已复制，可粘贴分享"))}),(c=document.getElementById("r-fav"))==null||c.addEventListener("click",()=>{const{fav:d}=J(t);this.haptic(),this.toast(d?"⭐ 已加入收藏":"已取消收藏"),this.renderResult(t)}),(h=document.getElementById("r-map-amap"))==null||h.addEventListener("click",()=>window.open(`https://uri.amap.com/marker?position=${t.lon},${t.lat}&name=${encodeURIComponent(t.ip)}&src=ipgeo`,"_blank")),(l=document.getElementById("r-map-g"))==null||l.addEventListener("click",()=>window.open(`https://www.google.com/maps?q=${t.lat},${t.lon}`,"_blank"))}resultText(t){return[`IP：${t.ip}`,`归属地：${m(t)||(t.isPrivate?"局域网地址":"未知")}`,t.isp&&`运营商：${t.isp}`,t.asn&&`ASN：${t.asn}`,t.lat!=null&&`经纬度：${t.lat}, ${t.lon}`,t.timezone&&`时区：${t.timezone}`,`数据源：${t.source}`,"—— IP 归属地查询"].filter(Boolean).join(`
`)}renderBatchTab(t){t.innerHTML=`
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
    `,document.getElementById("b-btn").addEventListener("click",()=>this.onBatch()),document.getElementById("b-clear").addEventListener("click",()=>{document.getElementById("b-input").value="",this.batchResults=[],this.renderBatchList(),this.toast("已清空")}),document.getElementById("b-export").addEventListener("click",async()=>{const e=this.batchResults.map(n=>`${n.ip}	${m(n)||(n.isPrivate?"内网":"查询失败")}`).join(`
`),s=await w(e);this.toast(s?"✅ 已复制全部结果":"❌ 复制失败")}),this.renderBatchList()}async onBatch(){const e=document.getElementById("b-input").value.split(/\n+/).map(c=>c.trim()).filter(Boolean);if(!e.length){this.toast("请先输入要查询的 IP / 域名");return}if(e.length>200){this.toast("单次最多 200 条");return}this.haptic(),this.batchResults=[],this.batchTotal=e.length,this.batchDone=0;const s=document.getElementById("b-prog");s.style.display="block";const n=document.getElementById("b-bar"),a=[...e],o=async()=>{for(;a.length;){const c=a.shift();let h=null;try{const l=B(c);if(l.kind==="invalid")h={ip:c,country:"格式错误",source:"-",time:Date.now()};else if(l.kind==="private")h={ip:l.value,country:"局域网 / 保留地址",isPrivate:!0,privateType:l.type,source:"本地识别",time:Date.now()};else{const d=l.kind==="domain"?await A(l.value):l.value;h=await R(d)}}catch{h={ip:c,country:"查询失败",source:"-",time:Date.now()}}this.batchResults.push(h),this.batchDone++,n.style.width=`${this.batchDone/this.batchTotal*100}%`,this.renderBatchList()}};await Promise.all([o(),o(),o()]),s.style.display="none",this.toast(`✅ 批量查询完成（${this.batchTotal} 条）`)}renderBatchList(){const t=document.getElementById("b-list"),e=document.getElementById("b-count"),s=document.getElementById("b-export");t&&(e&&(e.textContent=this.batchResults.length?`${this.batchResults.length} 条`:""),s&&(s.style.display=this.batchResults.length?"":"none"),t.innerHTML=this.batchResults.map(n=>`
      <div class="record-item" data-ip="${this.esc(n.ip)}">
        <div class="record-main">
          <div class="record-ip">${n.isPrivate?"🏠":I(n.countryCode)} ${this.esc(n.ip)}</div>
          <div class="record-sub">${this.esc(m(n)||"—")}</div>
        </div>
        <span class="record-time">${this.esc(n.isp??n.source??"")}</span>
      </div>`).join(""),t.querySelectorAll(".record-item").forEach(n=>n.addEventListener("click",()=>{this.currentTab="query",this.renderTabbar(),this.renderTab();const a=document.getElementById("q-input");a.value=n.dataset.ip,this.onQuery(a.value)})))}renderHistoryTab(t){var n;const e=y();t.innerHTML=`
      <div class="section-title">🕘 查询历史
        <span class="count">${e.length} 条（最多保留 100 条）</span>
        <span class="grow"></span>
        ${e.length?'<button class="btn-mini danger" id="h-clear">🗑️ 清空</button>':""}
      </div>
      <div class="record-list" id="h-list"></div>
    `;const s=document.getElementById("h-list");e.length?(s.innerHTML=e.map(a=>this.recordItemHtml(a)).join(""),this.bindRecordItems(s,"h",Z)):s.innerHTML='<div class="empty-box"><div class="big">🗂️</div>暂无查询记录</div>',(n=document.getElementById("h-clear"))==null||n.addEventListener("click",()=>{H(),this.toast("历史已清空"),this.renderTab()})}renderFavsTab(t){var n;const e=T();t.innerHTML=`
      <div class="section-title">⭐ 我的收藏
        <span class="count">${e.length} 条</span>
        <span class="grow"></span>
        ${e.length?'<button class="btn-mini danger" id="f-clear">🗑️ 清空</button>':""}
      </div>
      <div class="record-list" id="f-list"></div>
    `;const s=document.getElementById("f-list");e.length?(s.innerHTML=e.map(a=>this.recordItemHtml(a)).join(""),this.bindRecordItems(s,"f",W)):s.innerHTML='<div class="empty-box"><div class="big">⭐</div>还没有收藏<br>查询结果页点击「☆ 收藏」即可加入</div>',(n=document.getElementById("f-clear"))==null||n.addEventListener("click",()=>{x(),this.toast("收藏已清空"),this.renderTab()})}recordItemHtml(t){const e=t.result;return`
      <div class="record-item" data-ip="${this.esc(e.ip)}">
        <div class="record-main">
          <div class="record-ip">${e.isPrivate?"🏠":I(e.countryCode)} ${this.esc(e.ip)}</div>
          <div class="record-sub">${this.esc(m(e)||(e.isPrivate?e.privateType??"内网地址":"未知"))}</div>
        </div>
        <span class="record-time">${P(e.time)}</span>
        <button class="record-del" data-del="${this.esc(e.ip)}" title="删除">✕</button>
      </div>`}bindRecordItems(t,e,s){t.querySelectorAll(".record-del").forEach(n=>n.addEventListener("click",a=>{a.stopPropagation();const o=n.dataset.del;s(o),this.toast("已删除"),this.renderTab()})),t.querySelectorAll(".record-item").forEach(n=>n.addEventListener("click",()=>{this.currentTab="query",this.renderTabbar(),this.renderTab();const a=document.getElementById("q-input");a.value=n.dataset.ip,this.onQuery(a.value)}))}renderSettingsTab(t){t.innerHTML=`
      <div class="section-title">⚙️ 设置</div>
      <div class="settings-card">
        <div class="setting-row">
          <div class="setting-label">外观主题
            <div class="setting-sub">跟随系统或手动指定</div>
          </div>
          <div class="seg" id="s-theme">
            <button data-v="auto" class="${this.settings.theme==="auto"?"on":""}">自动</button>
            <button data-v="light" class="${this.settings.theme==="light"?"on":""}">浅色</button>
            <button data-v="dark" class="${this.settings.theme==="dark"?"on":""}">深色</button>
          </div>
        </div>
        <div class="setting-row">
          <div class="setting-label">震动反馈
            <div class="setting-sub">操作时轻微震动</div>
          </div>
          <button class="toggle ${this.settings.haptics?"on":""}" id="s-haptics"></button>
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
    `,document.getElementById("s-theme").querySelectorAll("button").forEach(e=>e.addEventListener("click",()=>{this.settings.theme=e.dataset.v,M(this.settings),this.applyTheme(),this.haptic(),this.renderTab()})),document.getElementById("s-haptics").addEventListener("click",()=>{this.settings.haptics=!this.settings.haptics,M(this.settings),this.haptic(),this.renderTab()}),document.getElementById("s-clear-all").addEventListener("click",()=>{H(),x(),this.toast("已清空全部历史与收藏"),this.renderTab()})}}const $=document.getElementById("app");new z($);window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change",()=>{location.hash=location.hash,window.dispatchEvent(new CustomEvent("theme-change"))});window.addEventListener("theme-change",()=>{$.innerHTML="",new z($)});
