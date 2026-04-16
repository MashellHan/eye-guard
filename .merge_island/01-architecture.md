# 合并后架构设计

## 当前架构对比

### EyeGuard (~12,646 lines)

```
EyeGuard/Sources/
├── App/          (1532)  AppDelegate, MenuBarView, Preferences
├── Mascot/       (2769)  阿普精灵渲染、动画、窗口、状态
├── Notifications/(1439)  休息覆盖层（全屏/微休息）
├── Exercises/    (1247)  眼保健操 UI + TTS 语音引导
├── Scheduling/   (823)   BreakScheduler 20-20-20 规则
├── Reporting/    (878)   健康评分、日报
├── Dashboard/    (739)   历史图表
├── AI/           (485)   LLM 洞察
├── Models/       (479)   数据模型
├── Analysis/     (445)   色温分析
├── Utils/        (416)   工具函数
├── Tips/         (393)   护眼小贴士
├── Audio/        (384)   音效 + TTS
├── Monitoring/   (242)   活动监控
├── Protocols/    (231)   协议抽象
├── Persistence/  (144)   数据持久化
```

**特点**: SwiftUI + NSWindow, 单窗口浮动精灵, MenuBar popover, 全屏 overlay

### MioIsland (~29,956 lines)

```
ClaudeIsland/
├── Services/     (11944)
│   ├── Session/  (3091)  SessionStore actor, 会话生命周期
│   ├── Sync/     (2948)  Mac ↔ iPhone 同步
│   ├── State/    (1777)  全局状态管理
│   ├── Hooks/    (1546)  Claude Code hooks 集成
│   ├── Window/   (659)   Notch 窗口管理
│   ├── Plugin/   (598)   原生插件系统
│   ├── Shared/   (499)   共享服务
│   ├── Tmux/     (425)   Tmux 监控
│   ├── Chat/     (276)   聊天消息
│   └── Cmux/     (125)   Claude multiplexer
├── UI/           (13073)
│   ├── Views/    (9667)  所有视图
│   ├── Components/(2719) 可复用组件
│   ├── Window/   (498)   窗口控制器
│   └── Helpers/  (189)   UI 工具
├── Core/         (2291)  Notch 几何、硬件检测、设置
├── Models/       (1923)  数据模型
├── App/          (251)   入口
```

**特点**: Swift Actor + Combine, NSPanel Notch overlay, 插件架构, Unix socket 通信

---

## 合并后架构

```
MioGuard/  (新项目名，暂定)
├── App/                        ← MioIsland App 入口，增加模式选择
│   ├── MioGuardApp.swift
│   └── AppDelegate.swift
│
├── Core/                       ← MioIsland Core + EyeGuard Utils 合并
│   ├── ModeManager.swift       ★ NEW: 双模式管理器
│   ├── NotchGeometry.swift     ← MioIsland
│   ├── NotchViewModel.swift    ← MioIsland, 扩展支持 EyeGuard 状态
│   ├── ScreenSelector.swift    ← MioIsland
│   ├── Settings.swift          ← 合并两边设置
│   ├── SoundManager.swift      ← 合并两边音效
│   ├── Logging.swift           ← EyeGuard
│   ├── TimeFormatting.swift    ← EyeGuard
│   └── NightModeManager.swift  ← EyeGuard
│
├── Mascot/                     ★ 统一精灵系统
│   ├── MascotProtocol.swift    ★ NEW: 精灵协议
│   ├── Apu/                    ← EyeGuard 阿普
│   │   ├── ApuRenderer.swift
│   │   ├── ApuAnimations.swift
│   │   └── ApuExpressions.swift
│   ├── PixelCat/               ← MioIsland 像素猫
│   │   ├── PixelCatRenderer.swift
│   │   └── NeonPixelCatView.swift
│   ├── MascotContainerView.swift  ← 统一容器
│   └── SpeechBubbleView.swift     ← EyeGuard
│
├── Modules/
│   ├── EyeGuard/               ★ 护眼模块（EyeGuard 核心功能打包）
│   │   ├── BreakScheduler.swift
│   │   ├── ActivityMonitor.swift
│   │   ├── BreakOverlayView.swift
│   │   ├── FullScreenOverlayView.swift
│   │   ├── ExerciseSession/
│   │   ├── HealthScore/
│   │   ├── Dashboard/
│   │   ├── DailyReport/
│   │   ├── Tips/
│   │   └── EyeGuardModule.swift  ★ 模块入口
│   │
│   └── Island/                 ★ 灵动岛模块（MioIsland 核心功能打包）
│       ├── SessionStore.swift
│       ├── HookSocketServer.swift
│       ├── SyncManager.swift
│       ├── ClaudeSessionMonitor.swift
│       └── IslandModule.swift    ★ 模块入口
│
├── Services/                   ← MioIsland Services（非模块特定）
│   ├── Plugin/
│   ├── Sync/
│   └── Window/
│
├── UI/                         ← 合并后统一 UI 层
│   ├── Notch/                  ← Notch 渲染
│   │   ├── NotchPanel.swift
│   │   ├── NotchShape.swift
│   │   └── NotchContentView.swift  ★ 根据模式切换内容
│   ├── MenuBar/                ← EyeGuard MenuBar
│   │   └── MenuBarView.swift
│   ├── Overlays/               ← EyeGuard 全屏覆盖
│   ├── Components/             ← 共享组件
│   └── Views/                  ← MioIsland Views
│
├── Models/                     ← 合并数据模型
├── Protocols/                  ← 合并协议
└── Persistence/                ← 合并持久化
```

## 依赖关系

```
                    ┌─────────────┐
                    │ ModeManager │
                    │ (Core)      │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              ▼                         ▼
    ┌─────────────────┐      ┌──────────────────┐
    │  EyeGuard Mode  │      │  Island Mode     │
    │  BreakScheduler │      │  SessionStore    │
    │  ActivityMonitor│      │  HookSocket      │
    │  Exercises      │      │  Sync            │
    └────────┬────────┘      └────────┬─────────┘
             │                        │
             └────────┬───────────────┘
                      ▼
            ┌──────────────────┐
            │  Shared Layer    │
            │  Mascot System   │
            │  Notch Rendering │
            │  Sound Manager   │
            │  Settings        │
            │  Plugin System   │
            └──────────────────┘
```

## 关键设计原则

1. **模块隔离** — EyeGuard 和 Island 各自独立，通过 AppModule 协议注入
2. **共享基础设施** — Notch 渲染、精灵、音效、设置是公共层
3. **同时运行** — 两个模式可以同时激活（护眼 + 监控并行）
4. **渐进迁移** — 先在 MioIsland 里嵌入 EyeGuard 模块，再统一 UI

---

## AppModule 协议 (Review #006 新增)

统一模块生命周期管理，ModeManager 通过协议控制模块：

```swift
protocol AppModule: AnyObject, Sendable {
    var id: String { get }
    var isActive: Bool { get }
    func activate()
    func deactivate()
    func handleEvent(_ event: AppEvent)
}
```

EyeGuardModule 和 IslandModule 各自实现此协议。ModeManager 切换模式时统一调用 `activate()`/`deactivate()`。

## 事件总线 (Review #006 新增)

模块间通信使用 `AsyncStream<AppEvent>`，与 MioIsland Actor 架构一致：

```swift
enum AppEvent: Sendable {
    // EyeGuard events
    case breakStarted(BreakType)
    case breakEnded
    case exerciseCompleted
    case healthScoreUpdated(Int)
    
    // Island events
    case sessionPhaseChanged(String)  // sessionId
    case approvalNeeded(String)
    
    // Shared events
    case modeChanged(AppMode)
    case screenLocked
    case screenUnlocked
}
```

## Notch Cutout (Review #006 新增)

全屏休息 overlay 在 Notch 区域留透明缺口，保持 Island 状态可见：

```swift
// FullScreenOverlayView 中
.mask {
    Rectangle()
        .overlay(alignment: .top) {
            NotchCutout()
                .blendMode(.destinationOut)
        }
        .compositingGroup()
}
```

