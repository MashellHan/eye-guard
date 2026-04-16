# Phase 3 详细规格：休息覆盖层移植

## 概述

移植 EyeGuard 的全屏/弹窗休息提醒 UI 到 mio-guard。这是用户最直接感受到的功能。

---

## 架构：EyeGuardModule 路由

BreakScheduler 通过回调触发休息，EyeGuardModule 负责路由到正确的 UI：

```swift
// EyeGuardModule.activate() 中
scheduler.onBreakTriggered = { [weak self] breakType in
    self?.showBreakOverlay(breakType)
}

// EyeGuardModule 新增方法
private func showBreakOverlay(_ type: BreakType) {
    switch type {
    case .micro:
        overlayManager.showMicroBreak()      // 20秒小弹窗
    case .macro:
        overlayManager.showMacroBreak()       // 5分钟全屏
    case .mandatory:
        overlayManager.showMandatoryBreak()   // 15分钟全屏+锁定
    }
}
```

---

## 3.3 OverlayWindow — 窗口管理

### 源文件：`eye-guard/EyeGuard/Sources/Notifications/OverlayWindow.swift`
### 目标：`mio-guard/ClaudeIsland/Modules/EyeGuard/UI/OverlayWindow.swift`

### 关键行为
- 全屏透明 NSWindow，level = `.screenSaver`
- 覆盖所有屏幕（`NSScreen.screens.forEach`）
- 点击穿透关闭（mandatory break 除外）

### Notch 共存适配 ⭐

**关键问题**：OverlayWindow level 高于 NotchPanel，会遮挡 Notch。

**解决方案**：

```swift
// OverlayWindow 在主屏的 Notch 区域留空
func setupOverlayMask(for screen: NSScreen) {
    guard screen == NSScreen.main else { return }
    
    let notchHeight: CGFloat = 38  // macOS notch 高度
    let notchWidth: CGFloat = 200  // 近似宽度
    
    // 如果 Island 模式激活，Notch 区域不遮挡
    if ModeManager.shared?.isIslandEnabled == true {
        // 在 SwiftUI 视图中用 .mask 留 Notch 缺口
    }
}
```

或者更简单：设置 OverlayWindow.level 低于 NotchPanel.level。

---

## 3.1 BreakOverlayView — 微休息 (20秒)

### 源文件：`eye-guard/EyeGuard/Sources/Notifications/BreakOverlayView.swift`
### 目标：`mio-guard/ClaudeIsland/Modules/EyeGuard/UI/BreakOverlayView.swift`

### UI 布局

```
┌──────────────────────────────────────────────────┐
│                                                  │
│              🐸 (阿普, 大尺寸 120pt)              │
│              "该休息了！"                          │
│                                                  │
│         ○○○○○○○○○○●●●●●  (倒计时环)              │
│              15 秒                               │
│                                                  │
│         💡 "向窗外看20英尺远的地方"                 │
│                                                  │
│         [跳过休息]                                │
│                                                  │
└──────────────────────────────────────────────────┘
```

### 移植注意
1. 阿普渲染改用 MascotContainer + ApuMiniView（overlay 模式 80pt）
2. 倒计时完成 → 调用 `EyeGuardModule.onBreakCompleted`
3. 跳过按钮 → 调用 `EyeGuardModule.skipBreak(type)`
4. ESC 键关闭（非 mandatory 时）

---

## 3.2 FullScreenOverlayView — 大休息 (5分钟/15分钟)

### 源文件：`eye-guard/EyeGuard/Sources/Notifications/FullScreenOverlayView.swift`
### 目标：`mio-guard/ClaudeIsland/Modules/EyeGuard/UI/FullScreenOverlayView.swift`

### UI 布局

```
┌──────────────────────────────────────────────────┐
│                                                  │
│              🐸 (阿普, 120pt)                    │
│              "认真休息一下吧！"                    │
│                                                  │
│         ╭──────────────────────╮                  │
│         │ ⏱ 4:32 / 5:00       │                  │
│         │ ████████████░░░░░░░░ │                  │
│         ╰──────────────────────╯                  │
│                                                  │
│         💡 护眼小贴士轮播                          │
│                                                  │
│    [🏋 开始眼保健操]     [跳过休息]               │
│                                                  │
│    Today: 0/2 exercises completed                │
│                                                  │
└──────────────────────────────────────────────────┘
```

### Mandatory Break 特殊行为
- ESC 键不能关闭
- 跳过按钮有延迟（5 秒后才出现）
- 摇晃动画提示"按 ESC 无法跳过"
- MandatoryShakeModifier 一并移植

---

## 3.4 MandatoryShakeModifier

### 源文件：`eye-guard/EyeGuard/Sources/Notifications/MandatoryShakeModifier.swift`
### 目标：`mio-guard/ClaudeIsland/Modules/EyeGuard/UI/MandatoryShakeModifier.swift`

直接复制，无需修改。纯 SwiftUI modifier。

---

## 3.5 OverlayManager (新增)

替代原来的 NotificationManager，专门管理 overlay 窗口：

```swift
@MainActor
final class EyeGuardOverlayManager {
    
    private var overlayWindows: [NSWindow] = []
    
    func showMicroBreak() {
        let view = BreakOverlayView(breakType: .micro, ...)
        showOverlay(view: view, onAllScreens: false)  // 微休息只在主屏
    }
    
    func showMacroBreak() {
        let view = FullScreenOverlayView(breakType: .macro, ...)
        showOverlay(view: view, onAllScreens: true)
    }
    
    func showMandatoryBreak() {
        let view = FullScreenOverlayView(breakType: .mandatory, ...)
        showOverlay(view: view, onAllScreens: true)
    }
    
    func dismissAll() {
        overlayWindows.forEach { $0.close() }
        overlayWindows.removeAll()
    }
    
    private func showOverlay(view: some View, onAllScreens: Bool) {
        let screens = onAllScreens ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
        for screen in screens {
            let window = OverlayWindow(screen: screen, content: view)
            window.makeKeyAndOrderFront(nil)
            overlayWindows.append(window)
        }
    }
}
```

---

## 文件清单

| 文件 | 来源 | 行数估计 |
|------|------|----------|
| `Modules/EyeGuard/UI/OverlayWindow.swift` | 移植 | ~80 |
| `Modules/EyeGuard/UI/BreakOverlayView.swift` | 移植+适配 | ~200 |
| `Modules/EyeGuard/UI/FullScreenOverlayView.swift` | 移植+适配 | ~350 |
| `Modules/EyeGuard/UI/MandatoryShakeModifier.swift` | 直接复制 | ~40 |
| `Modules/EyeGuard/UI/EyeGuardOverlayManager.swift` | 新建 | ~80 |

## 测试清单

- [ ] 微休息弹窗显示 20 秒倒计时后自动关闭
- [ ] 大休息全屏覆盖所有屏幕
- [ ] Mandatory break 无法 ESC 关闭
- [ ] 跳过按钮正确调用 skipBreak
- [ ] 倒计时完成正确调用 onBreakCompleted
- [ ] Notch panel 在 overlay 之上或留缺口可见（Island 模式时）
- [ ] 阿普使用 MascotContainer overlay 模式 (80pt)
