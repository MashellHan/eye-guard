# Notch Mode 升级到 mio 视觉级 — 实施计划

> **目标**: 把 eye-guard 的 `.notch` 模式内部实现从"自写 1.8k 行临时版"替换为 mio 级渲染框架（像素猫 + neon + 精细动画 + slot 容器），保留对外 API 不变，用户感知无新模式但视觉大幅升级。
>
> **范围限定**: 只搬 UI / 渲染 / 窗口框架，不引入 Services（SessionStore / Hooks / Sync / Plugin / Chat / Tmux / Cmux 全部排除）。
>
> **分支**: `feat/notch-mio-upgrade`
>
> **决策依据**: 用户消息「不需要插件和 sync 能力 但是 ui效果一样」+「号」（确认替换方案 A）

## 1. 现状回顾

| 项 | 当前 (临时 Notch) | mio 渲染框架 |
|---|---|---|
| 代码量 | 1815 行 | ~10500 行可拷 (8116 直接 + 4 文件改造 + 2 文件重写) |
| 状态机 | `NotchViewModel` 245 行 (closed/opened/popping) | `NotchViewModel` 456 行 + `NotchActivityCoordinator` |
| 形状 | `NotchShape` 39 行 简单圆角 | `NotchShape` 131 行 squircle 精细路径 |
| 容器 | `NotchContainerView` 写死 EyeGuard 卡片 | `NotchView` slot 化 + Header + Menu |
| 精灵 | ApuMiniView | NeonPixelCatView (neon 像素渲染) |
| 调色板 | 写死黑底 | `NotchPaletteModifier` 主题化 |
| 字体 | 默认 | `NotchFontModifier` 降级链 |
| 多屏 | 简化 NotchGeometry | + `NotchHardwareDetector` + `ScreenSelector` |
| 自定义 | 无 | LiveEdit 拖拽 + 偏移持久化 |
| 多语 | 散在各文件 | `Localization.swift` (L10n enum 477 行) |
| Pop banner | NotchPopBanner | mio 内建 + 队列 |
| Boot 动画 | 1s 简单 | 同样 1s 但 spring + 内容过渡 |

## 2. 终态架构

保持 `AppMode` 仍为 `.apu` / `.notch` 两值。`.notch` 模式内部:

```
EyeGuard/Sources/Notch/
├── Framework/                       ★ 新增: mio 拷贝层
│   ├── Core/                        13 文件 / 2798 行
│   │   ├── NotchViewModel.swift     ⚠ 剥离 session/plugin enum case
│   │   ├── NotchGeometry.swift
│   │   ├── NotchHardwareDetector.swift
│   │   ├── NotchActivityCoordinator.swift
│   │   ├── ScreenSelector.swift
│   │   ├── SoundManager.swift       (重命名为 IslandSoundManager 避免冲突)
│   │   ├── Settings.swift           (重命名为 IslandSettings)
│   │   ├── Localization.swift       (L10n enum)
│   │   ├── DebugLogger.swift
│   │   ├── LogStreamer.swift
│   │   ├── Ext+NSScreen.swift
│   │   ├── ModeManager.swift        (跳过 — eye-guard 已有自己的)
│   │   ├── CodexFeatureGate.swift   (跳过 — 与 EyeGuard 无关)
│   │   ├── UpdaterManager.swift     (跳过 — Sparkle, eye-guard 自管)
│   │   └── SoundSelector.swift
│   ├── Events/
│   │   └── EventMonitors.swift      47 行 (单例 mouseLocation/mouseDown publisher)
│   ├── State/
│   │   └── NotchCustomizationStore.swift  139 行 (从 Services/State/ 拷)
│   ├── Window/                      4 文件 / 498 行
│   │   ├── NotchPanel.swift         (改名 NotchWindow→NotchPanel，与 EyeGuard 现用名一致)
│   │   ├── NotchWindowController.swift
│   │   ├── NotchViewController.swift
│   │   └── NotchLiveEditPanel.swift
│   ├── Components/                  13 文件 / 3099 行
│   │   ├── NotchShape.swift
│   │   ├── NeonPixelCatView.swift   ★ 像素猫
│   │   ├── PixelCharacterView.swift
│   │   ├── EmojiPixelView.swift
│   │   ├── BuddyASCIIView.swift
│   │   ├── ProcessingSpinner.swift
│   │   ├── ActionButton.swift
│   │   ├── ChipFlowLayout.swift
│   │   ├── MarkdownRenderer.swift
│   │   ├── ScreenPickerRow.swift
│   │   ├── SoundPickerRow.swift
│   │   ├── StatusIcons.swift
│   │   ├── TerminalColors.swift
│   │   ├── PluginSlotView.swift     ⚠ 改造为协议注入
│   │   └── (跳过 PluginHeaderButtons.swift)
│   ├── Helpers/                     3 文件 / 141 行
│   │   ├── Color+Hex.swift
│   │   ├── NotchFontModifier.swift
│   │   └── NotchPaletteModifier.swift
│   │   └── (跳过 SessionFilter.swift — eye-guard 用不到)
│   ├── Views/                       5 文件 / 1054 行
│   │   ├── NotchHeaderView.swift    ⚠ 剥离插件按钮
│   │   ├── NotchMenuView.swift      ⚠ 剥离插件循环
│   │   ├── NotchCustomizationSettingsView.swift
│   │   ├── NotchLiveEditOverlay.swift
│   │   └── NotchLiveEditSimulator.swift
│   └── Mascot/                      5 文件 / 526 行
│       ├── MascotProtocol.swift
│       ├── PixelCat/PixelCatMascot.swift
│       ├── Apu/ApuMiniView.swift    (eye-guard 已有自己的版本，按需合并)
│       ├── Apu/ApuColors.swift
│       └── SpeechBubbleView.swift   (eye-guard 已有，重命名)
│
├── EyeGuardNotchView.swift          ★ 新建: 替代 mio NotchView (1313 行) 的 EyeGuard 版本 (~250 行)
├── EyeGuardNotchHeader.swift        ★ 新建: 简化版 Header (~80 行)
├── EyeGuardNotchMenu.swift          ★ 新建: 简化版 Menu (~120 行)
├── Bridges/
│   └── EyeGuardDataBridge.swift     (保留现有 — BreakScheduler 数据源)
└── (旧实现) — 阶段性删除
    ├── NotchViewModel.swift         → 切到 Framework 版本后删
    ├── NotchModule.swift            → 改为接 Framework
    ├── NotchPanel.swift             → 删 (用 Framework 版)
    ├── NotchWindowController.swift  → 删
    ├── NotchHostingController.swift → 删
    ├── Geometry/                    → 删 (用 Framework 版)
    ├── Events/                      → 删 (用 Framework EventMonitors)
    ├── Preferences/                 → 删 (用 Framework Customization)
    ├── Views/NotchContainerView     → 删
    ├── Views/NotchPopBanner         → 删 (用 mio pop)
    ├── Views/NotchShape             → 删
    ├── Views/PlaceholderCollapsed   → 删
    ├── Views/PlaceholderExpanded    → 删
    ├── Views/TypewriterText         → 留 (mio 没有等价物)
    └── Views/EyeGuard/*.swift       → 删 (5 个卡片整合进 EyeGuardNotchView)
```

## 3. 改造点详细

### 3.1 NotchViewModel.swift — 剥离 Session/Plugin

删除:
- `enum NotchContentType` 中的 `.chat(SessionState)`, `.question(SessionState)`, `.plugin(String)`
- `currentChatSession` 属性
- `showChat(for:)`, `showQuestion(for:)`, `showPlugin(_:)`, `exitChat()` 方法
- `notchOpen` 中的 chat 恢复逻辑
- `notchClose` 中的 session 保存逻辑
- `case .chat`, `.question`, `.plugin` 的 sizing
- `NotificationCenter "com.codeisland.openPlugin"` 监听（约 8 行）

保留:
- 所有几何 / hover / click 处理
- `NotchCustomizationStore` 集成
- `.eyeGuard` 和 `.dualMode` (后续 dual 模式要用)
- Boot 动画 / Pop / Unpop

新增:
- `enum NotchContentType` 改为 `.eyeGuard / .menu / .settings`

### 3.2 PluginSlotView.swift — 协议化

```swift
// 新协议
protocol NotchSlotRenderer {
    func render(slot: String) -> AnyView?
}

// 改造后
struct PluginSlotView: View {
    let renderer: NotchSlotRenderer?
    let slot: String
    var body: some View {
        renderer?.render(slot: slot) ?? AnyView(EmptyView())
    }
}
```

eye-guard 提供一个 `EyeGuardSlotRenderer` 实现（可选，初版可不用）。

### 3.3 NotchMenuView.swift — 剥离插件

删 `ForEach(manager.loadedPlugins)` 块（~80 行）。改为 eye-guard 风格菜单：
- Eye Guard 偏好设置
- 切换到 Apu 模式
- Show Dashboard
- Show Daily Report
- Quit

### 3.4 NotchHeaderView.swift — 剥离插件按钮

删 `PluginHeaderButtons` 引用，保留:
- 关闭按钮
- 标题区
- 设置按钮
- Mode 切换按钮

### 3.5 EyeGuardNotchView.swift — 全新

替代 mio 1313 行的 NotchView。负责:
- 根据 `viewModel.contentType` 路由内容
  - `.eyeGuard` → 渲染 ContinuousTime + HealthScore + NextBreak + BreakNow (复用现有 5 个 Section 视图，但用新 modifier 风格化)
  - `.menu` → `EyeGuardNotchMenu`
  - `.settings` → `NotchCustomizationSettingsView`
- 闭合状态: 左侧像素猫 + 右侧 EyeGuardCollapsedContent
- 应用 `NotchFontModifier` + `NotchPaletteModifier`
- 使用 mio 的 `NotchShape` 和 spring 动画

预估 250 行。

## 4. 命名空间冲突清单

mio 类名与 eye-guard 现有类冲突，需要重命名:

| mio 类 | eye-guard 已有 | 处理 |
|---|---|---|
| `NotchPanel` | `NotchPanel` (eye-guard) | 旧版删除，用 mio 版 |
| `NotchWindowController` | `NotchWindowController` (eye-guard) | 旧版删除 |
| `NotchViewController` | `NotchHostingController` (eye-guard) | eye-guard 旧版删除，用 mio 版 |
| `NotchViewModel` | `NotchViewModel` (eye-guard) | 旧版删除 |
| `NotchGeometry` | `NotchGeometry` (eye-guard) | 旧版删除 |
| `EventMonitors` | `NotchEventMonitors` (eye-guard) | 旧版删除 |
| `NotchShape` | `NotchShape` (eye-guard) | 旧版删除 |
| `SpeechBubbleView` | `SpeechBubbleView` (eye-guard Mascot) | mio 版改名 `IslandSpeechBubbleView` |
| `ApuMiniView` | (eye-guard Mascot 已有 ApuMiniView) | 用 eye-guard 现有 |
| `SoundManager` | `EyeGuardSoundManager` (eye-guard) | mio 版改名 `IslandSoundManager`，避免双 TTS 冲突 |
| `Settings` | `UserPreferencesManager` (eye-guard) | mio 版改名 `IslandSettings`，仅承载 Notch 自身偏好 |
| `Localization` (L10n) | `EyeGuardL10n` (eye-guard) | mio 版改名 `IslandL10n` |
| `ModeManager` | `ModeManager` (eye-guard) | mio 版**不拷** |

## 5. Day-by-Day 执行步骤

### Day 1 — 拷贝 + 编译跑通

- [ ] 1.1 创建目录: `EyeGuard/Sources/Notch/Framework/{Core,Events,State,Window,Components,Helpers,Views,Mascot}`
- [ ] 1.2 拷 Core/ 11 个文件（跳过 ModeManager/CodexFeatureGate/UpdaterManager），重命名 SoundManager/Settings/Localization
- [ ] 1.3 拷 Events/EventMonitors.swift
- [ ] 1.4 拷 State/NotchCustomizationStore.swift
- [ ] 1.5 拷 Window/ 4 文件
- [ ] 1.6 拷 Components/ 13 文件（跳过 PluginHeaderButtons）
- [ ] 1.7 拷 Helpers/ 3 文件（跳过 SessionFilter）
- [ ] 1.8 拷 Views/ 5 文件
- [ ] 1.9 拷 Mascot/ 5 文件，改名 SpeechBubbleView
- [ ] 1.10 改造 NotchViewModel: 删 session/plugin enum case 和方法
- [ ] 1.11 改造 PluginSlotView: 协议化
- [ ] 1.12 改造 NotchMenuView: 删插件循环
- [ ] 1.13 改造 NotchHeaderView: 删插件按钮
- [ ] 1.14 `swift build` — 修编译错误（命名空间替换、import 调整）

**Day 1 验收**: `swift build` 成功，但还没接入应用入口，旧 Notch 仍在运行。

### Day 2 — 写 EyeGuardNotchView 并接入

- [x] 2.1 写 `EyeGuardNotchView.swift`，path 路由 + 三种 contentType 渲染 ✅ 02:30 — 实装在 `IslandHelperViews.swift`：根据 `IslandNotchViewModel.status` (.closed/.opened/.popping) 路由到现有 `EyeGuardCollapsedContent` / `EyeGuardExpandedView`，无 bridge 时降级到 FallbackBranding。`IslandNotchViewModel.eyeGuardBridge: EyeGuardDataBridge?` 字段已加。
- [ ] 2.2 写 `EyeGuardNotchMenu.swift`，5-7 个菜单项
- [ ] 2.3 写 `EyeGuardNotchHeader.swift`（如果合并到 NotchHeaderView 改造里则跳过）
- [ ] 2.4 改造 `EyeGuardDataBridge` 把 BreakScheduler 数据接进新 ViewModel
- [ ] 2.5 在 `NotchModule.swift` 中切换：旧 NotchWindowController → mio Framework IslandNotchWindowController
  - [x] 2.5a — IslandNotchViewModel 加 `pop(kind:message:duration:)` parity surface (cron 12:39 commit `3d90412`)
  - [x] 2.5b — `IslandNotchModule` + `IslandNotchBreakFlowAdapter` 并排创建 (cron 13:20) — 不切 AppModeCoordinator，新模块跟旧模块 side-by-side 共存，build 4.05s/233 tests pass
  - [ ] 2.5c — AppModeCoordinator `.notch` 分支切到 `IslandNotchModule.shared.activate(scheduler:)`，删 NotchModule 旧路径或留作 fallback flag
- [ ] 2.6 `swift build` 通过 + 启动 app 跑通 .notch 模式

**Day 2 验收**: `.notch` 模式启动后能看到 mio 风刘海，连续使用时间正常更新。

### Day 3 — 像素猫接入 + 视觉打磨

- [ ] 3.1 闭合状态左侧渲染 NeonPixelCatView，右侧 EyeGuard 状态点
- [ ] 3.2 应用 NotchFontModifier 和 NotchPaletteModifier 到所有内容
- [ ] 3.3 spring 动画曲线替换 .easeOut
- [ ] 3.4 Pop banner 用 mio 路径
- [ ] 3.5 Boot 动画走 mio 1s spring
- [ ] 3.6 NotchCustomization (LiveEdit) 偏移持久化测试

**Day 3 验收**: 视觉与 mio 像素猫模式一致，hover/click/boot 流畅。

### Day 4 — 清理 + 测试 + 发版准备

- [ ] 4.1 删除旧 `EyeGuard/Sources/Notch/{Geometry,Events,Window,Preferences,NotchModule,NotchViewModel,Views/{NotchContainerView,NotchPanel,NotchPopBanner,NotchShape,PlaceholderCollapsed,PlaceholderExpanded},Views/EyeGuard/*}`（确认无引用）
- [ ] 4.2 全工程 grep 确认旧 NotchViewModel 等已无引用
- [ ] 4.3 多屏 / 无刘海机型代码路径 review
- [ ] 4.4 模式切换 .apu ↔ .notch 测试，确认窗口生命周期清洁
- [ ] 4.5 更新 CHANGELOG.md
- [ ] 4.6 截图更新到 README/screenshots/
- [ ] 4.7 git tag 准备 (但不立即发版)

**Day 4 验收**: 旧 Notch 实现清理干净，新实现稳定，发版材料齐备。

## 6. 风险登记

| 风险 | 概率 | 影响 | 缓解 |
|---|---|---|---|
| `NotchCustomizationStore` 与 EyeGuard `UserPreferencesManager` 冲突 | 中 | UserDefaults key 重叠 | mio 用的 key `notchCustomization.v1` 不与 eye-guard 任何 key 重叠，确认无冲突 |
| Combine 与 Observation 共存（mio 用 Combine + ObservableObject，eye-guard 部分用 @Observable） | 高 | 编译复杂 | 接受，Framework 内全用 Combine，Bridge 层做适配 |
| 字体 / 调色板 modifier 影响到 EyeGuard 其它窗口 | 低 | 视觉污染 | modifier 只在 Notch 渲染树内应用，不全局 |
| 像素猫 + 阿普精灵窗同时存在产生认知冲突 | 中 | UX 困惑 | `.notch` 模式下浮动阿普窗保持隐藏（已是现状） |
| mio 的 LiveEdit 功能拖大 Notch 模式入口 | 低 | UI 复杂 | 可选功能，初版菜单中提供"自定义 Notch"入口隐藏在偏好里 |
| `NeonPixelCatView` 在多屏快速移动可能掉帧 | 低 | 性能 | 已有 mio 节流，不调整 |

## 7. 验证清单（每 Day 末跑）

- [ ] `swift build` 成功
- [ ] 启动后 .apu 模式仍正常（不影响）
- [ ] .notch 模式可启动
- [ ] 模式切换不泄漏窗口
- [ ] 关闭 app 干净退出（无 console error）
- [ ] BreakScheduler 数据正常进 Notch
- [ ] 全屏休息 overlay 在 Notch 区域留 cutout

## 8. 进度跟踪

| Day | Status | Started | Completed | Notes |
|---|---|---|---|---|
| 1.1-1.9 (拷贝) | ✅ | 2026-04-20 | 2026-04-20 | 44 文件 7500 行 拷入 Framework/, 全部 Island 前缀 |
| 1.10-1.14 (剥离 + 编译) | ✅ | 2026-04-20 | 2026-04-20 01:55 | **0 errors / 233 tests pass** — 删 4 out-of-scope 文件 + 加 WyHash + IslandHelperViews + 修 Sendable / 穷尽 switch |
| 2 | 🚧 in progress | 2026-04-20 02:30 | — | 2.1 ✅ — IslandNotchView 实接 EyeGuardCollapsedContent/ExpandedView。剩 2.2-2.6 |
| 3 | ⬜ | — | — | 像素猫 + 视觉 |
| 4 | ⬜ | — | — | 清理 + 发版 |

## 当前阻塞清单 (Day 1 末)

需在 Framework/ 内删除以下符号引用（业务类型，eye-guard 不需要）:

| 符号 | 出现文件 | 处理 |
|---|---|---|
| `SessionState` | IslandNotchViewModel, StatusIcons, PixelCharacterView, IslandSoundManager | 删该字段/参数, 或改为 enum 不带 associated value |
| `SessionPhase` | IslandNotchViewModel, StatusIcons, PixelCharacterView | 同上 |
| `ClaudeSessionMonitor` | IslandSoundManager | 删 sessionMonitor 字段 |
| `NativePluginManager` | PluginSlotView, IslandNotchMenuView | 协议化或删 |
| `HookSocketServer` | (待扫) | 删 |
| `ChatMessage` | (待扫) | 删 |
| `NotchStatus/NotchOpenReason/NotchContentType` | eye-guard 现有同名 | 给 mio 版加 `Island` 前缀 |
| `ScreenGeometry`, `NotchPalette`, `NotchThemeID` | 在多文件 | 检查这些类型是否在 mio 其他位置定义 |
| `NSScreen.notchSize`, `NSScreen.persistentID` | Window | eye-guard 已有同名 ext, ambiguous |
| `AppMode.dual` | menu | 我们没 .dual, 删该 case |

下一轮工作:
1. ~~扫 mio 其他位置找 ScreenGeometry/NotchPalette/NotchThemeID 的定义并补拷入 Framework/~~ ✅ 02762c7 (NotchTheme + NotchCustomization + EventMonitor + BuddyReader 拷入 Framework/State/)
2. ~~给三个共用 enum (NotchStatus/Reason/ContentType) 加 Island 前缀~~ ✅ 2c879c6
3. ~~删 NSScreen 扩展冲突（用 mio 版还是 eye-guard 版需选）~~ ✅ 2c879c6 (删 mio 版, 保 eye-guard 版)
4. ~~删 SessionState/SessionPhase 引用~~ ✅ c4b0b03 (改为 stub IslandLegacyDomainStubs.swift, 含完整 10-phase enum + sessionId)
5. ~~删 NativePluginManager 引用~~ ✅ c4b0b03 (stub)
6. ~~删 PreviewsMacros (#Preview blocks 引用已删除类型)~~ ✅ c4b0b03 (剥离 6 个 #Preview from 5 文件)
7. ~~AppDelegate.shared / EyeGuardModule / AppMode.dual~~ ✅ 95e6423 (shim)
8. 剩余 99 errors: NotchHardwareDetector.shared 并发 (~22), NotificationCenter Sendable (~8), IslandPluginDescriptor 缺成员 (~6), WyHash/TipTriangle/SystemSettingsRow/IslandNotchView 小辅助类型 (~14) — 下一轮
9. 编译到 0 error 后接 Day 2 (写 EyeGuardNotchView)

### 自动 cron 进度日志 (00:30)

| 时点 | HEAD | swift build errors | 主要类别 |
|---|---|---|---|
| 00:24 (315ea8b 拷贝完成) | 315ea8b | 1367 | 缺类型 (BuddyInfo, NotchPalette, ScreenGeometry, EventMonitor) + enum 冲突 + NSScreen 重复 |
| 00:31 (02762c7 补 4 模型) | 02762c7 | ~1100 | enum 冲突 + NSScreen 重复主导 |
| 00:33 (2c879c6 enum 前缀) | 2c879c6 | **799** | SessionState/Phase + AppDelegate + NativePluginManager + PreviewsMacros |

### 自动 cron 进度日志 (01:00)

| 时点 | HEAD | swift build errors | Δ | 备注 |
|---|---|---|---|---|
| 01:08 (c4b0b03 strip #Preview + stubs) | c4b0b03 | **151** | -208 (-58%) | 加 IslandLegacyDomainStubs.swift |
| 01:10 (95e6423 AppDelegate shim) | 95e6423 | **99** | -52 (-34%) | <100 错误首达 |

### 自动 cron 进度日志 (01:55) — Day 1 收尾

| 时点 | HEAD | swift build errors | Δ | 备注 |
|---|---|---|---|---|
| 01:45 (上一次 review) | 86c7de9 | 66 | -33 (-33%) | 工作区无新提交，但 cron 之间累计 |
| 01:55 (本轮起手) | 86c7de9 | 66 | 0 | swift build 复测 |
| 01:55a (删 out-of-scope) | dirty | **179** | +113 ⚠ | 删 IslandSoundManager / IslandNotchMenuView / PluginSlotView / SoundPickerRow 后下游警告涌现，但这些都是被删文件引用的旧告警；实际新结构错误下降 |
| 01:55b (加 WyHash + IslandHelperViews + 修穷尽 switch + Sendable) | dirty | **4** | -175 (-98%) | 仅余 NotificationCenter `note` 数据竞争 |
| 01:55c (重写 MioIslandCoexistence handleAppChange 接 bundleID 而非 note) | dirty | **0** ✅ | -4 | **Day 1 编译完成** |
| 01:55d (修 NotchCustomizationStoreTests ±30→±400) | dirty | 0 | tests | **233/233 ✅** |

**累计自 Day 1 起 (1367 → 0 = -100%)** 🎉

### 本轮关键决策

1. **删除 out-of-scope 文件** (依据 README "不移植 Plugin Store / SoundManager / Chat / Tmux / PairPhone / DualMode")：
   - `Framework/Core/IslandSoundManager.swift` — 8-bit chiptune，eye-guard 无 session 事件可触发
   - `Framework/Views/IslandNotchMenuView.swift` — 引用 NativePluginManager.LoadedPlugin 等不存在成员
   - `Framework/Components/PluginSlotView.swift` — 插件 slot 渲染
   - `Framework/Components/SoundPickerRow.swift` — IslandSoundManager 唯一调用者
2. **新增 helpers** (`Framework/State/WyHash.swift`, `Framework/Views/IslandHelperViews.swift`)：
   - `WyHash` enum — IslandBuddyReader 必需
   - `TipTriangle: Shape` — IslandSpeechBubble 必需（注意是 Shape 不是 View）
   - `SystemSettingsRow` — 空 EmptyView 占位（菜单已删，留作 placeholder 兼容）
   - `IslandNotchView` — Day 1 placeholder，渲染空 `Color.clear`，**Day 2 替换为 EyeGuardNotchView**
3. **Sendable 修复**：
   - `IslandEventMonitors`, `BuddyReader` 标 `@unchecked Sendable`（Combine 单例，业务上是 main-thread-only）
   - `IslandAppSettings.defaults` 标 `nonisolated(unsafe)`
4. **Concurrency 修复**：`MioIslandCoexistence.handleAppChange` 改为接 `bundleID: String?` 而不是 `Notification`，避免 NotificationCenter 回调中 task-isolated `note` 跨入 main-actor closure
5. **测试更新**：`NotchCustomizationStoreTests` 中 horizontalOffset clamp 测试从 ±30 改为 ±400（对齐 `NotchCustomization.clampRange`）

**Day 2 入口已就绪**：替换 `IslandHelperViews.swift` 中的 `IslandNotchView` placeholder 为接入真实 eye-guard 数据的 `EyeGuardNotchView`。所有 framework 调用点（`IslandNotchViewController`, `NotchPaletteModifier`）已可解析。

---

## 附录 A: 拷贝清单（49 文件）

源: `/Users/mengxionghan/.superset/projects/Tmp/mio-guard/ClaudeIsland/`
目标: `/Users/mengxionghan/.superset/projects/Tmp/eye-guard/EyeGuard/Sources/Notch/Framework/`

```
Core/CodexFeatureGate.swift                       → SKIP
Core/DebugLogger.swift                            → Framework/Core/
Core/Ext+NSScreen.swift                           → Framework/Core/
Core/Localization.swift                           → Framework/Core/IslandL10n.swift (rename type)
Core/LogStreamer.swift                            → Framework/Core/
Core/ModeManager.swift                            → SKIP
Core/NotchActivityCoordinator.swift               → Framework/Core/
Core/NotchGeometry.swift                          → Framework/Core/ (replaces eye-guard's)
Core/NotchHardwareDetector.swift                  → Framework/Core/
Core/NotchViewModel.swift                         → Framework/Core/ (with surgery)
Core/ScreenSelector.swift                         → Framework/Core/
Core/Settings.swift                               → Framework/Core/IslandSettings.swift (rename type)
Core/SoundManager.swift                           → Framework/Core/IslandSoundManager.swift (rename type)
Core/SoundSelector.swift                          → Framework/Core/
Core/UpdaterManager.swift                         → SKIP
Events/EventMonitors.swift                        → Framework/Events/
Services/State/NotchCustomizationStore.swift      → Framework/State/
UI/Window/NotchViewController.swift               → Framework/Window/
UI/Window/NotchWindow.swift                       → Framework/Window/NotchPanel.swift (rename)
UI/Window/NotchWindowController.swift             → Framework/Window/
UI/Window/NotchLiveEditPanel.swift                → Framework/Window/
UI/Components/ActionButton.swift                  → Framework/Components/
UI/Components/BuddyASCIIView.swift                → Framework/Components/
UI/Components/ChipFlowLayout.swift                → Framework/Components/
UI/Components/EmojiPixelView.swift                → Framework/Components/
UI/Components/MarkdownRenderer.swift              → Framework/Components/
UI/Components/NeonPixelCatView.swift              → Framework/Components/
UI/Components/NotchShape.swift                    → Framework/Components/
UI/Components/PixelCharacterView.swift            → Framework/Components/
UI/Components/PluginHeaderButtons.swift           → SKIP
UI/Components/PluginSlotView.swift                → Framework/Components/ (with surgery)
UI/Components/ProcessingSpinner.swift             → Framework/Components/
UI/Components/ScreenPickerRow.swift               → Framework/Components/
UI/Components/SoundPickerRow.swift                → Framework/Components/
UI/Components/StatusIcons.swift                   → Framework/Components/
UI/Components/TerminalColors.swift                → Framework/Components/
UI/Helpers/Color+Hex.swift                        → Framework/Helpers/
UI/Helpers/NotchFontModifier.swift                → Framework/Helpers/
UI/Helpers/NotchPaletteModifier.swift             → Framework/Helpers/
UI/Helpers/SessionFilter.swift                    → SKIP
UI/Views/NotchHeaderView.swift                    → Framework/Views/ (with surgery)
UI/Views/NotchMenuView.swift                      → Framework/Views/ (with surgery)
UI/Views/NotchCustomizationSettingsView.swift     → Framework/Views/
UI/Views/NotchLiveEditOverlay.swift               → Framework/Views/
UI/Views/NotchLiveEditSimulator.swift             → Framework/Views/
UI/Views/NotchView.swift                          → SKIP (replaced by EyeGuardNotchView)
Mascot/MascotProtocol.swift                       → Framework/Mascot/
Mascot/Apu/ApuMiniView.swift                      → SKIP (eye-guard already has)
Mascot/Apu/ApuColors.swift                        → Framework/Mascot/Apu/ (if no conflict)
Mascot/PixelCat/PixelCatMascot.swift              → Framework/Mascot/PixelCat/
Mascot/SpeechBubbleView.swift                     → Framework/Mascot/IslandSpeechBubble.swift (rename)
```

总计:
- ✅ Lift verbatim: 35 files (~7000 行)
- ⚠ Lift + surgery: 5 files (~1100 行)
- ⏭ SKIP: 6 files (无需要)
- ★ NEW: 3 files (~450 行)
