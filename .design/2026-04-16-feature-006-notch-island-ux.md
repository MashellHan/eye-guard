# Feature Design: Notch Island UX — 借鉴 MioIsland 的 Dynamic Island 交互模式

**Date:** 2026-04-16
**Status:** Ready
**Priority:** P1
**Reference:** [MioMioOS/MioIsland](https://github.com/MioMioOS/MioIsland)

---

## ⚠️ 双模式架构

EyeGuard 支持两种显示模式，用户可在偏好设置中切换：

| 模式 | 名称 | 描述 |
|------|------|------|
| `.classic` | 经典模式 | 当前实现：Menu Bar 图标 + 独立浮动精灵窗口 + 全屏弹窗 |
| `.island` | 灵动岛模式 | 新增：精灵常驻 Notch + 展开面板 + 全屏弹窗 |

**现有代码完全保留。** 两种模式共享：
- `BreakScheduler`（调度引擎）
- `NotificationManager`（通知升级链）
- `OverlayWindowController`（全屏弹窗）
- `SoundManager`（音效/TTS）
- `HealthScoreCalculator`（健康分）
- `ExerciseSessionView`（眼保健操全屏）

```swift
enum DisplayMode: String, CaseIterable {
    case classic  // Menu Bar + 浮动精灵
    case island   // Notch Dynamic Island
}

// UserPreferencesManager
@AppStorage("displayMode") var displayMode: DisplayMode = .classic
```

### 模式切换架构

```
                    AppDelegate
                        │
              ┌─────────┼─────────┐
              ▼                   ▼
    DisplayMode.classic     DisplayMode.island
              │                   │
     ┌────────┴────────┐   ┌─────┴──────┐
     │ MenuBarManager   │   │ NotchManager│
     │ MascotWindow     │   │ NotchPanel  │
     │ Controller       │   │ NotchView   │
     └────────┬────────┘   └─────┬──────┘
              │                   │
              └────────┬──────────┘
                       ▼
              ┌─────────────────┐
              │  共享核心引擎     │
              │  BreakScheduler  │
              │  NotificationMgr │
              │  SoundManager    │
              │  OverlayWindow   │
              └─────────────────┘
```

---

## MioIsland 项目调研总结

MioIsland 是一个 macOS Dynamic Island 应用，将 MacBook 的 notch（刘海）区域变成一个可交互的状态面板。核心技术：

### 架构亮点

| 维度 | MioIsland 实现 | 值得借鉴 |
|------|---------------|---------|
| **窗口技术** | `NSPanel` + `.nonactivatingPanel` + `ignoresMouseEvents` 动态切换 | ✅ 不打断用户焦点，关闭时完全透明穿透 |
| **Notch 形状** | `NotchShape` 使用 `Path` + quadratic curves 精确模拟刘海形状 | ✅ 视觉融合感极强 |
| **展开/收起** | 收起=刘海两侧翼展（collapsed wings），展开=下拉面板 | ✅ 类 iOS Dynamic Island 体验 |
| **层级管理** | 收起: `.mainMenu + 3`（不遮挡菜单栏），展开: `.popUpMenu`（高于一切） | ✅ 精确的层级切换 |
| **硬件检测** | `NotchHardwareDetector` 通过 `screen.safeAreaInsets.top > 0` 判断是否有物理 notch | ✅ 虚拟 notch 作为后备 |
| **状态动画** | 像素猫 6 种动画状态（idle/working/needsYou/thinking/error/done） | ✅ 生动的状态反馈 |
| **交互方式** | 全局事件监听器（hover 展开，click 激活），非传统窗口交互 | ✅ 极低侵入感 |
| **音效系统** | 8-bit chiptune 音效，每个事件可独立开关 | ✅ 可定制的感官反馈 |

### 关键代码模式

```swift
// 1. NSPanel 不抢焦点
class NotchPanel: NSPanel {
    init(...) {
        super.init(styleMask: [.borderless, .nonactivatingPanel], ...)
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        ignoresMouseEvents = true  // 关闭时穿透
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        level = .mainMenu + 3
    }
}

// 2. 动态切换交互状态
viewModel.$status.sink { status in
    switch status {
    case .opened:
        window.ignoresMouseEvents = false   // 展开时接受交互
        window.level = .popUpMenu           // 提到最高
    case .closed:
        window.ignoresMouseEvents = true    // 收起时穿透
        window.level = .mainMenu + 3        // 降回正常
    }
}

// 3. Notch 几何计算
struct NotchGeometry {
    let deviceNotchRect: CGRect
    func collapsedScreenRect(expansionWidth: CGFloat) -> CGRect
    func openedScreenRect(for size: CGSize) -> CGRect
    func isPointInNotch(_ point: CGPoint) -> Bool
}
```

---

## EyeGuard Notch Island Spec

### 1. 概述

将 EyeGuard 的精灵（阿普）从独立浮动窗口迁移到 MacBook notch 区域，采用 MioIsland 的 Dynamic Island 交互模式。精灵常驻刘海，休息提醒和眼保健操从刘海展开为全屏覆盖。

### 2. 交互状态

```
┌─────────────────────────────────────────────────────────────┐
│                        NOTCH 区域                            │
│                                                              │
│  ┌──────────────────────────────────────┐                    │
│  │  收起态 (Collapsed)                   │                    │
│  │  ┌─────┬──────────────┬─────────┐    │                    │
│  │  │ 🐸  │ 距休息 18:32  │ ❤️ 85  │    │                    │
│  │  │阿普  │              │         │    │                    │
│  │  └─────┴──────────────┴─────────┘    │                    │
│  └──────────────────────────────────────┘                    │
│                     │                                        │
│         ┌───────────┼───────────┐                            │
│         ▼           ▼           ▼                            │
│    点击展开      Hover 预览     自动展开                       │
│                                                              │
│  ┌──────────────────────────────────────┐                    │
│  │  展开态 (Expanded)                    │                    │
│  │                                      │                    │
│  │  🐸 阿普                              │                    │
│  │  距下次休息: 18:32                     │                    │
│  │  今日已休息: 5 次                      │                    │
│  │  眼睛健康分: 85/100                    │                    │
│  │                                      │                    │
│  │  [立刻休息]  [眼保健操]  [暂停]        │                    │
│  │                                      │                    │
│  │  ⚙️ 设置    📊 报告                   │                    │
│  └──────────────────────────────────────┘                    │
│                                                              │
│                     │                                        │
│                     ▼                                        │
│              预提醒/休息弹窗                                   │
│        (全屏覆盖，复用现有逻辑)                                │
└─────────────────────────────────────────────────────────────┘
```

### 3. 状态机

```
                    ┌──────────┐
                    │  Closed  │ ◄── 点击区域外 / ESC / 自动折叠
                    │ (收起态)  │
                    └────┬─────┘
                         │
              ┌──────────┼──────────┐
              │ click    │ hover    │ auto (预提醒)
              ▼          ▼          ▼
         ┌──────────┐  ┌──────┐  ┌──────────┐
         │  Opened  │  │ Peek │  │ Popping  │
         │ (完全展开) │  │(预览) │  │ (弹跳动画)│
         └──────────┘  └──────┘  └──────────┘
              │                       │
              │    ┌──────────────────┘
              ▼    ▼
         ┌──────────────┐
         │  Full Screen  │ ◄── 休息弹窗 / 眼保健操
         │  (全屏覆盖)    │
         └──────────────┘
```

### 4. 收起态 (Collapsed) — 精灵常驻刘海

#### 4.1 视觉设计

```
         ┌─────────── notch 宽度 ───────────┐
         │                                   │
    ◄────┼── wing ──┤  hardware  ├── wing ──┼────►
         │          │   notch    │           │
    ┌────┴──────────┴───────────┴───────────┴────┐
    │  🐸   距休息 18:32          ❤️85  ●        │
    └────────────────────────────────────────────┘
         精灵     倒计时文字      健康分  状态点
```

- **精灵 (阿普):** 缩小到 ~16x16pt，放在左侧翼展区
- **倒计时:** "距休息 MM:SS"，文字跑马灯（内容过长时轮播）
- **健康分:** 心形图标 + 分数，颜色随分数变化（绿/黄/红）
- **状态点:** 颜色指示当前状态
  - 🟢 绿色 = 正常
  - 🟡 黄色 = 即将休息 (< 2min)
  - 🟠 橙色 = 连续使用过长 (> 45min)
  - 🔴 红色 = 必须休息 (mandatory)

#### 4.2 精灵动画状态

借鉴 MioIsland 的像素猫 6 态设计：

| 状态 | 精灵表情 | 触发条件 |
|------|---------|---------|
| idle | 正常，偶尔眨眼 | 正常使用中 |
| concerned | 眼睛变琥珀色，微微皱眉 | 连续使用 > 45 分钟 |
| alerting | 弹跳动画 + 发光 | 预提醒倒计时 |
| resting | 闭眼打盹 | 休息中 |
| celebrating | 开心跳跃 ✨ | 完成休息/眼保健操 |
| exercising | 跟着做眼操 | 眼保健操进行中 |

#### 4.3 翼展动态宽度

```swift
var expansionWidth: CGFloat {
    guard isActive else { return 0 }  // 暂停时无翼展
    
    // 紧凑模式: 仅图标 + 状态点
    if compactMode { return 80 }
    
    // 完整模式: 图标 + 倒计时 + 健康分 + 状态点
    return 200
}
```

### 5. 展开态 (Expanded) — 替代 Menu Bar 弹出面板

#### 5.1 布局

```
┌────────────────────────────────────┐
│         ┌──────────────┐           │
│         │  notch area  │           │
│         └──────┬───────┘           │
│                │                    │
│   🐸 阿普 (大尺寸)                  │
│                                    │
│   ┌─ 状态卡片 ──────────────────┐  │
│   │  距下次休息     18:32       │  │
│   │  今日已休息     5 次        │  │
│   │  眼睛健康分     85/100      │  │
│   │  连续使用       32 分钟     │  │
│   │  今日屏幕时长   4 小时 22 分 │  │
│   └────────────────────────────┘  │
│                                    │
│   ┌─ 快捷操作 ──────────────────┐  │
│   │  [🧘 立刻休息]  [👁️ 眼保健操] │  │
│   │  [⏸️ 暂停]     [📊 健康报告]  │  │
│   └────────────────────────────┘  │
│                                    │
│   ⚙️ 偏好设置                      │
└────────────────────────────────────┘
```

#### 5.2 尺寸计算

```swift
var openedSize: CGSize {
    CGSize(
        width: min(screenRect.width * 0.35, 400),
        height: 420
    )
}
```

### 6. 预提醒态 (Pre-Alert) — 从 Notch 弹出

#### 6.1 交互流

```
T-10s: 收起态 → Popping 弹跳动画
       精灵状态: idle → alerting
       状态点: 绿 → 黄
       音效: alert chime

T-10s ~ T-0s: 翼展区显示倒计时 "还有 10 秒"
              精灵弹跳 + 发光脉冲

T-5s: 收起态翼展显示倒计时数字 "5...4...3..."
      TTS: 语音倒计时

T-0s: 收起态 → 全屏覆盖 (现有 FullScreenOverlayView)
      精灵状态: alerting → resting
```

#### 6.2 气泡按钮 (feature-004 补完)

预提醒期间在 notch 下方弹出操作气泡：

```
         ┌───────────────┐
         │   notch area  │
         └───────┬───────┘
                 │
        ┌────────┴────────┐
        │ 🐸 还有 8 秒...  │
        │                  │
        │ [立刻休息] [延后]  │
        └──────────────────┘
```

- **立刻休息:** 立即进入全屏休息
- **延后:** 推迟 5 分钟 (postpone)

### 7. 窗口技术实现

#### 7.1 NotchPanel (借鉴 MioIsland)

```swift
class EyeGuardNotchPanel: NSPanel {
    init(screen: NSScreen) {
        super.init(
            contentRect: windowFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        level = .mainMenu + 3
        ignoresMouseEvents = true  // 默认穿透
    }
}
```

#### 7.2 状态切换

```swift
// 收起: 穿透，不抢焦点
func collapse() {
    panel.ignoresMouseEvents = true
    panel.level = .mainMenu + 3
}

// 展开: 接受交互
func expand() {
    panel.ignoresMouseEvents = false
    panel.level = .popUpMenu
    // 不抢焦点（hover 触发时）
    panel.orderFrontRegardless()
}

// 全屏休息: 使用现有的 CGShieldingWindowLevel
func showBreakOverlay() {
    collapse()  // 先收起 notch
    // 复用现有的 OverlayWindowController 逻辑
}
```

#### 7.3 Notch 几何

```swift
struct EyeGuardNotchGeometry {
    let screen: NSScreen
    
    var hasPhysicalNotch: Bool {
        screen.safeAreaInsets.top > 0
    }
    
    var notchRect: CGRect {
        if hasPhysicalNotch {
            return CGRect(x: ..., y: ..., width: screen.notchWidth, height: notchHeight)
        } else {
            // 虚拟 notch: 屏幕顶部中央，高 32pt
            return CGRect(x: screenMidX - 100, y: screenMaxY - 32, width: 200, height: 32)
        }
    }
    
    func collapsedRect(expansionWidth: CGFloat) -> CGRect { ... }
    func expandedRect(size: CGSize) -> CGRect { ... }
    func isPointInNotch(_ point: CGPoint) -> Bool { ... }
}
```

### 8. 双模式集成架构

#### 8.1 模式对照表

| 功能 | Classic 模式 | Island 模式 |
|------|-------------|------------|
| 精灵显示 | `MascotWindowController` 浮动窗口 | Notch 收起态 16x16 |
| 状态面板 | `MenuBarView` popover | Notch 展开态 |
| Peek 模式 | 精灵从屏幕边缘探出 | 不需要（始终在 notch） |
| 预提醒 | 精灵弹出 + speech bubble | Notch 弹跳 + 气泡按钮 |
| 休息弹窗 | `FullScreenOverlayView` | 同（共享） |
| 眼保健操 | `ExerciseSessionView` 全屏 | 同（共享） |
| Menu Bar 图标 | ✅ 显示 | ❌ 隐藏（可选保留） |

#### 8.2 共享组件（两种模式均使用）

| 组件 | 说明 |
|------|------|
| `BreakScheduler` | 核心调度引擎 |
| `NotificationManager` | 通知升级链 |
| `OverlayWindowController` | 全屏弹窗创建 |
| `SoundManager` | 音效/TTS |
| `HealthScoreCalculator` | 健康分计算 |
| `ExerciseSessionView` | 眼保健操 UI |
| `FullScreenOverlayView` | 休息弹窗 UI |

#### 8.3 DisplayModeController 协议

```swift
/// 两种模式的统一接口
protocol DisplayModeController: AnyObject {
    /// 启动模式（创建窗口、注册事件）
    func activate()
    /// 停用模式（销毁窗口、移除事件）
    func deactivate()
    /// 更新精灵状态
    func updateMascotState(_ state: MascotState)
    /// 显示消息气泡
    func showMessage(_ text: String, duration: TimeInterval)
    /// 预提醒开始
    func handlePreAlertStarted(breakType: BreakType, seconds: Int)
    /// 预提醒倒计时
    func handlePreAlertCountdown(seconds: Int)
    /// 预提醒取消
    func handlePreAlertCancelled()
}

/// Classic 模式实现（包装现有 MascotWindowController）
class ClassicModeController: DisplayModeController { ... }

/// Island 模式实现（新增）
class IslandModeController: DisplayModeController { ... }
```

#### 8.4 模式切换逻辑

```swift
// AppDelegate 或 AppCoordinator
func switchDisplayMode(to mode: DisplayMode) {
    currentController?.deactivate()
    
    switch mode {
    case .classic:
        currentController = ClassicModeController(...)
        menuBarManager.show()
    case .island:
        currentController = IslandModeController(...)
        menuBarManager.hide()  // 或保留为精简图标
    }
    
    currentController?.activate()
}
```

### 9. 非 Notch 设备支持

iMac、外接显示器等无 notch 设备：

- **方案:** 虚拟 notch — 在屏幕顶部中央绘制一个模拟刘海形状
- **MioIsland 方案:** `NotchHardwareDetector.hasHardwareNotch` 返回 false 时自动切换
- **EyeGuard 方案:** 同理，无 notch 时绘制虚拟岛形控件在屏幕顶部

### 10. 实施分期

#### Phase 0: 双模式基础架构 (P0)
- `DisplayMode` 枚举 + `@AppStorage`
- `DisplayModeController` 协议
- `ClassicModeController` 包装现有 `MascotWindowController`
- 偏好设置 UI 中增加模式切换
- **现有代码零修改**，仅新增抽象层

#### Phase 1: 基础 Notch 面板 (P0)
- `IslandModeController` 实现
- `EyeGuardNotchPanel` 窗口（NSPanel）
- `NotchGeometry` 几何计算
- 收起态：精灵 + 倒计时 + 健康分
- 展开态：状态信息 + 快捷按钮
- Hover/Click 事件监听

#### Phase 2: 精灵动画迁移 (P1)
- 精灵 16x16 缩略渲染
- 6 种动画状态在 notch 中运行
- 状态点颜色联动

#### Phase 3: 预提醒集成 (P1)
- 预提醒从 notch 弹出气泡
- 气泡按钮（立刻休息/延后）
- 倒计时数字在翼展显示

#### Phase 4: 虚拟 Notch (P2)
- 无 notch 设备支持
- 虚拟岛形状渲染
- 可拖拽位置

### 11. 变更文件预估

| File | Change | Phase |
|------|--------|-------|
| `Sources/App/DisplayMode.swift` | **新建** — 枚举 + 协议 | 0 |
| `Sources/App/ClassicModeController.swift` | **新建** — 包装现有 MascotWindowController | 0 |
| `Sources/App/AppCoordinator.swift` | **新建** — 模式切换调度 | 0 |
| `Sources/App/PreferencesView.swift` | 增加模式切换 Picker | 0 |
| `Sources/Notch/IslandModeController.swift` | **新建** — Island 模式实现 | 1 |
| `Sources/Notch/EyeGuardNotchPanel.swift` | **新建** — NSPanel 子类 | 1 |
| `Sources/Notch/NotchGeometry.swift` | **新建** — 几何计算 | 1 |
| `Sources/Notch/NotchViewModel.swift` | **新建** — 状态管理 | 1 |
| `Sources/Notch/NotchView.swift` | **新建** — 收起态 SwiftUI | 1 |
| `Sources/Notch/NotchExpandedView.swift` | **新建** — 展开态 SwiftUI | 1 |
| `Sources/Notch/NotchShape.swift` | **新建** — 刘海形状 Path | 1 |
| `Sources/Mascot/MascotWindowController.swift` | **不修改**（由 ClassicModeController 包装） | 0 |
| `Sources/App/MenuBarView.swift` | **不修改**（Classic 模式继续使用） | - |
| `Sources/Scheduling/BreakScheduler.swift` | **不修改** | - |
| `Sources/Notifications/NotificationManager.swift` | **不修改** | - |

### 12. 风险

| 风险 | 缓解 |
|------|------|
| NSPanel 在不同 macOS 版本行为差异 | 仅支持 macOS 14+ (Sonoma)，与现有要求一致 |
| 全局事件监听器 accessibility 权限 | MioIsland 已验证可行，需提示用户授权 |
| 多屏幕 notch 选择 | 跟随主屏幕，与 MioIsland 一致 |
| 性能：精灵动画常驻 | 16x16 缩略图 + 低帧率 (15fps)，CPU 开销极小 |
| 与 MenuBar 图标共存过渡期 | Phase 1 期间两者共存，稳定后可移除 menu bar |
