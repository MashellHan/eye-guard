# 双模式切换系统设计

## 概念

用户可以在两个模式间切换，也可以同时开启两个模式：

| 模式 | 标识 | Notch 内容 | 精灵 | 额外 UI |
|------|------|-----------|------|---------|
| 🛡 Eye Guard | `.eyeGuard` | 连续使用时间 + 健康评分 + 下次休息倒计时 | 阿普 | 全屏休息覆盖、MenuBar |
| 🏝 Island | `.island` | Claude Code 会话列表 + 实时状态 | 像素猫 | — |
| 🔀 Dual | `.dual` | 分区显示：左翼=护眼，右翼=Island | 两者交替 | 全部 |

## 模式管理器

```swift
@MainActor
class ModeManager: ObservableObject {
    enum AppMode: String, CaseIterable {
        case eyeGuard = "eye_guard"
        case island = "island"
        case dual = "dual"
    }
    
    @Published var currentMode: AppMode = .dual
    @Published var eyeGuardEnabled: Bool = true
    @Published var islandEnabled: Bool = true
    
    // 模式切换时的回调
    var onModeChanged: ((AppMode) -> Void)?
    
    func switchMode(to mode: AppMode) {
        currentMode = mode
        eyeGuardEnabled = (mode == .eyeGuard || mode == .dual)
        islandEnabled = (mode == .island || mode == .dual)
        onModeChanged?(mode)
    }
}
```

## Notch 布局方案

### Eye Guard Mode — Notch 展开后

```
┌─── Notch ───────────────────────────────────────────┐
│                    [  刘海  ]                         │
│  ┌────────────────────────────────────────────────┐  │
│  │  🛡 已连续使用屏幕 2h 35m                       │  │
│  │  ████████████████░░░░  下次休息: 4m 32s         │  │
│  │                                                │  │
│  │  健康评分: 78/100 🟢                            │  │
│  │  [📊 Dashboard]  [🏋 做操]  [⚙ 设置]           │  │
│  └────────────────────────────────────────────────┘  │
│          [阿普在 Notch 左侧探头]                      │
└──────────────────────────────────────────────────────┘
```

### Island Mode — 保持 MioIsland 原有 UI

```
┌─── Notch ───────────────────────────────────────────┐
│              🐱  [  刘海  ]                          │
│  ┌────────────────────────────────────────────────┐  │
│  │  Session 1: 🟢 Processing    2m ago            │  │
│  │  Session 2: 🟡 Waiting       5m ago            │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### Dual Mode — 左右分区

```
┌─── Notch ───────────────────────────────────────────┐
│       [阿普]  [  刘海  ]  [🐱]                       │
│  ┌──── EyeGuard ────┐  ┌──── Island ──────────┐    │
│  │ 连续 2h35m       │  │ Session: Processing  │    │
│  │ 休息: 4m32s 🟢   │  │ Tool: Read file.ts   │    │
│  └──────────────────┘  └──────────────────────┘    │
└──────────────────────────────────────────────────────┘
```

## Notch 收起状态 (Closed)

精灵显示在 Notch 两侧：

```
Eye Guard Mode:    [阿普😊] ████████ [健康:78]
Island Mode:       [🐱idle] ████████ [2 sessions]
Dual Mode:         [阿普😊] ████████ [🐱 2s]
```

## 切换入口

1. **Notch 右键菜单** → Switch Mode → Eye Guard / Island / Dual
2. **Menu Bar** → Mode 切换按钮
3. **快捷键** — `⌘⇧M` 循环切换
4. **设置** → Default Mode 选择

## 模式持久化

```swift
// UserDefaults
"mioguard.mode" → "eye_guard" | "island" | "dual"
"mioguard.eyeguard.enabled" → true/false
"mioguard.island.enabled" → true/false
```

## 模式切换动画

切换时 Notch 内容做一个 300ms 的 crossfade transition：

```swift
withAnimation(.easeInOut(duration: 0.3)) {
    modeManager.switchMode(to: newMode)
}
```

精灵切换：阿普向左滑出 → 像素猫从右滑入（或反向）

## 模式间交互

| 场景 | 行为 |
|------|------|
| Island 模式下到了休息时间 | 自动临时切换到 EyeGuard 显示休息提醒，结束后切回 |
| Dual 模式下 Claude 需要批准 | Island 区域闪烁提醒 |
| 眼保健操进行中 | 全屏覆盖，两个模式都暂停 Notch 更新 |
| 锁屏解锁 | EyeGuard 重置计时，Island 检查 session 状态 |
