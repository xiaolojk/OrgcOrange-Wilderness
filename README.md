# 《橘子荒野》Orange Wilderness

> **Orgc橘子工作室** 出品 · 像素风荒野生存开放世界 · Android 10+
> 引擎：**Godot 4.3**（GDScript） · **CI 编译 APK 零许可证**

一款星露谷物语风格像素画的开放世界荒野生存游戏。玩家随风暴漂流至被"灰雾"侵蚀的橘子岛，采集、狩猎、生存，并在古老铁砧上锻造装备，最终净化岛屿。

## 为什么选 Godot

| 对比 | Unity | **Godot** |
|---|---|---|
| CI 编译 APK | 要 Unity 许可证（手机获取门槛高） | **完全免费开源，零许可证** |
| 手机触发构建 | 受阻于许可证 | **只需 GitHub 令牌** |
| 像素画 | 适配繁琐 | 原生 2D 像素友好 |

## 核心玩法

- **生存系统**：饱食 / 水分 / 体力 / 生命 / 体温，受昼夜与天气影响
- **锻造式制作**：把材料放上铁砧 → 点击「锻造」即可产出（材料匹配即成，无需记配方）
- **主线「灰雾与橘子」** 五章：
  1. 漂流上岸 — 采集浆果与木头
  2. 灰雾之源 — 挖掘铁矿石
  3. 锻造传承 — 锻造铁锭、铁刃
  4. 净雾护符 — 锻造净雾护符
  5. 橘子重生 — 净化橘子岛
- **触屏控制**：左半屏动态虚拟摇杆 + 右下「行动」按钮（按下即响应，灵敏低延迟）

## 操作

| 操作 | 触屏 | 键盘（PC 测试） |
|---|---|---|
| 移动 | 左半屏拖拽摇杆 | WASD / 方向键 |
| 交互/采集/锻造 | 右下「行动」按钮 | E / 空格 |

## 项目结构

```
OrgcOrange-Wilderness/
├── project.godot              # Godot 项目配置（Android/像素画/输入）
├── export_presets.cfg         # Android 导出预设（arm64+armv7）
├── scenes/
│   └── Main.tscn              # 入口场景（挂 main.gd，运行时程序化装配）
├── scripts/
│   ├── g.gd                   # 全局总线（autoload 单例，事件信号）
│   ├── items.gd               # 物品目录（class_name Items）
│   ├── pixel_art.gd           # 程序化像素画（星露谷风格化调色）
│   ├── world.gd               # 地形噪声 + 昼夜 + 天气
│   ├── survival.gd            # 生存属性系统
│   ├── player.gd              # 玩家 + 触屏/键盘移动 + 交互
│   ├── resource_node.gd       # 树/灌木/岩石/铁矿/水源采集
│   ├── forge.gd               # 锻造铁砧
│   ├── quest.gd               # 五章主线
│   ├── ui.gd                  # 中文 HUD（属性条/任务/提示/品牌/时钟）
│   ├── touch_controls.gd      # 触屏摇杆 + 行动按钮
│   ├── forge_panel.gd         # 锻造面板 UI
│   └── main.gd                # 运行时程序化装配全部系统
└── .github/workflows/
    └── build-android.yml      # Godot CI：导出 APK + 自动发 Release（零许可证）
```

## 本地运行（可选，有电脑时）

1. 下载 [Godot 4.3](https://godotengine.org/download)（免费，无需安装，单文件）
2. 启动 Godot → 导入本项目 `project.godot`
3. 按 ▶ 运行（Android 导出模板已配置）

## GitHub Actions 自动编译 APK（推荐，手机即可）

工作流 `build-android.yml` 会在 push 到 `main` 或打 `v*` 标签时自动触发：
- 在云端安装开源 Godot + 导出模板 + Android SDK（**全部免费，无需任何许可证或账号**）
- 导出 `OrangeWilderness.apk`
- 打标签时自动创建 GitHub Release 并上传 APK

### 你只需要做（手机操作）

1. **生成 GitHub 令牌**（`github.com` → Settings → Developer settings → Personal access tokens → Tokens (classic) → 勾选 `repo`），把 `ghp_` 开头的令牌发给我，我推送代码
2. 代码推送后，push 到 `main` 会自动编译；打标签 `v1.0.0` 会编译并发布 Release：
   ```
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. Release 页面即可下载 `OrangeWilderness.apk`，手机允许"未知来源"后安装

**无许可证、无账号、无序列号——全程手机可控。**

## 技术说明

- **运行时程序化装配**：`main.gd` 在 `_ready()` 构建全部系统，无需手写场景节点，CI 导出零配置即可运行
- **程序化像素画**：`pixel_art.gd` 运行时生成全部 16×16 精灵（瓦片噪点 + 角色/物品 ASCII 调色板手绘），点采样像素完美，无美术文件依赖
- **中文渲染**：Godot 4 在 Android 自带 Noto Sans CJK，中文默认可显示
- **Android 适配**：min_sdk=29（Android 10），arm64+armv7 双架构，覆盖 vivo 全系

## 许可

代码与生成素材 © Orgc橘子工作室。替换美术后可用于商业发行。
