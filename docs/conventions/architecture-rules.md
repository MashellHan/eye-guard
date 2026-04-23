# EyeGuard 架构规则

> 这些是**硬约束**。reviewer 会按此评审，违反必须 CHANGES_REQUESTED。

## 模块依赖图（允许的方向）

```
                ┌──────────────────────┐
                │   Sources/App/       │  (入口、菜单栏、Coordinator)
                └──────────┬───────────┘
                           ↓
        ┌──────────────────┼──────────────────┐
        ↓                  ↓                  ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ Sources/     │  │ Sources/     │  │ Sources/     │
│  Mascot/     │  │  Notch/      │  │  Dashboard/  │   ← View 层
│  Exercises/  │  │              │  │  Reporting/  │      (互不依赖)
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                  │                  │
       └──────────────────┼──────────────────┘
                          ↓
                ┌──────────────────────┐
                │ Sources/Scheduling/  │  ← 业务逻辑（核心）
                │ Sources/Monitoring/  │     可被任何 view 读
                │ Sources/Notifications│     不能依赖任何 view
                │ Sources/Audio/       │
                │ Sources/AI/          │
                │ Sources/Analysis/    │
                └──────────┬───────────┘
                           ↓
                ┌──────────────────────┐
                │ Sources/Models/      │  ← 底座
                │ Sources/Protocols/   │     不依赖任何东西
                │ Sources/Persistence/ │
                │ Sources/Tips/        │
                │ Sources/Utils/       │
                └──────────────────────┘
```

## 硬规则

### R1. 业务逻辑禁止依赖 view 层
`Scheduling/`、`Monitoring/`、`Reporting/`、`Notifications/`、`Audio/`、`AI/`、`Analysis/` 中的代码：
- ❌ 不能 `import SwiftUI`（除非纯类型如 `Color` 用于状态枚举映射）
- ❌ 不能引用 `NSWindow` / `NSView` / `View` 协议实现
- ❌ 不能引用 `MascotView` / `NotchOverlayView` / `MenuBarView`
- ✅ 可以发布 `@Observable` 状态供 view 订阅

### R2. 显示模式互不依赖
`Sources/Mascot/` 和 `Sources/Notch/` 之间：
- ❌ 不能互相 import
- ✅ 都依赖 `ModeManager` / `BreakScheduler` 等共享业务层
- ✅ 通过 `AppModeCoordinator` 协调切换

### R3. 单例白名单
仅以下单例允许存在：
- `ModeManager.shared`
- `NightModeManager.shared`
- `SoundManager.shared`
- `ReportDataProvider.shared`

新增单例需修改本文件并说明理由。

### R4. 跨模块依赖必须用协议
新加的跨模块依赖必须先在 `Sources/Protocols/` 定义协议，再注入实现。
反例：`MascotView` 直接 `BreakScheduler()` 实例化 — ❌
正例：`MascotView` 接受 `any BreakSchedulerProtocol` 注入 — ✅

### R5. Persistence 兼容性
- JSON 字段改名 / 删除时**必须**写 migration（在 `Sources/Persistence/` 内）
- 新字段必须有合理默认值，旧版本 JSON 仍可加载
- 涉及 daily report 文件格式时要看 `docs/conventions/persistence-migration.md`（如不存在，先建）

### R6. 医学常量必须标注来源
`Constants.swift` 或别处的 break 时长、间隔、阈值等数字必须有注释引用：
- AAO（American Academy of Ophthalmology）
- OSHA Computer Workstation Guidelines
- EU Directive 90/270/EEC
- NIOSH

例：
```swift
/// 20 分钟 = AAO 20-20-20 Rule (Jeffrey Anshel)
static let microBreakInterval: TimeInterval = 20 * 60
```

### R7. Tier 1/2/3 提醒升级链
`Notifications/` 模块下的提醒升级链是核心 invariant：
- Tier 1: System notification
- Tier 2: Floating overlay (`BreakOverlayView`)
- Tier 3: Full-screen overlay (`FullScreenOverlayView`)

任何改动不能：
- 跳过 tier
- 改变 tier 升级时序（默认 2min → 5min）
- 让 tier 互相依赖

### R8. BreakScheduler 状态机不变量
- `currentSession` 在任何时刻最多一个
- 暂停时所有 timer 停止，恢复时基于暂停前的剩余时间重启（不丢进度）
- `idle detected` → 自动暂停；`idle ended` → 自动恢复
- 新功能不能直接修改 `currentSession`，必须走 scheduler 的 public API

## 软规则（建议）

### S1. 新 module 加在哪
- 跨业务和视图的 → 业务层（`Sources/<Name>/`）
- 纯渲染的 → 看属于 Mascot 还是 Notch 还是通用（`Sources/Components/` 可新建）
- 数据模型 → `Sources/Models/`
- 跨模块协议 → `Sources/Protocols/`

### S2. 文件大小
- 单文件 ≤ 400 行
- 单类型 ≤ 300 行
- 单函数 ≤ 50 行
（超了要在 PR 描述里说明，reviewer 会问）

### S3. View 拆分
SwiftUI View 一旦超过 5 个 section，拆成子 view（甚至子 file）。
