# Phase 1 — Notch Shell（跑通灵动岛空壳）

> **目标**：一个在菜单栏刘海区域悬浮、可 hover 展开、click 开合的透明 NSPanel。**不包含任何护眼业务逻辑**，只要能证明 Notch 窗口 + 动画 + 事件系统能在 Eye Guard SPM 项目里跑通。

## 交付物

### 新增源码（`EyeGuard/Sources/Notch/`）

```
Notch/
├── NotchModule.swift                  # 入口，activate()/deactivate()
├── NotchViewModel.swift               # @Observable 状态机
├── Geometry/
│   ├── NotchGeometry.swift            # 纯函数几何
│   ├── NSScreen+Notch.swift           # notchSize/isBuiltinDisplay/hasPhysicalNotch
│   └── NotchHardwareDetector.swift    # 软件 notch 的 fallback 尺寸
├── Window/
│   ├── NotchPanel.swift               # NSPanel 子类
│   ├── NotchWindowController.swift    # 生命周期 + 事件绑定
│   └── NotchHostingController.swift   # SwiftUI host
├── Events/
│   └── NotchEventMonitors.swift       # 全局鼠标事件（throttle 50ms）
└── Views/
    ├── NotchShape.swift               # 圆角刘海路径
    ├── NotchContainerView.swift       # 收起/展开 master
    ├── PlaceholderCollapsed.swift     # 占位收起态（只显示一个点）
    └── PlaceholderExpanded.swift      # 占位展开态（只显示 "Hello Notch"）
```

### 修改现有代码

- `EyeGuard/Sources/App/EyeGuardApp.swift`（或 AppDelegate 等效入口）
  - 在 `applicationDidFinishLaunching` 里 `NotchModule.shared.activate(on: .main)`
- `Package.swift` — 无需改（已包含 `EyeGuard/Sources`）

### 新增测试

- `EyeGuard/Tests/NotchTests/NotchGeometryTests.swift` — 4+ 个 `@Test`
  - 刘海 rect 计算
  - 开合 rect 计算
  - 点命中测试（inside/outside/edge）
  - horizontalOffset 偏移

## Rewrite 规范（不是复制！）

### 1. 必须改动

| Mio 原样 | Eye Guard 要求 | 理由 |
|---------|--------------|------|
| `ObservableObject` + `@Published` | `@Observable` (Swift 6.0) | Eye Guard 已在用新 API |
| `Combine` 订阅 | `Observation` + `withObservationTracking` 或 `onChange` | 减少 Combine 依赖 |
| 类名带 `Claude`/`Mio` | 统一用 `Notch` 前缀 | Eye Guard 不是 Mio |
| 1313 行 NotchView | 拆 ≤ 400 行 / 文件 | 遵守 Eye Guard coding-style |
| `NotificationCenter` plugin hook | **去掉** | 不需要 plugin 系统 |

### 2. 保留的机制

- **NSPanel with `.borderless, .nonactivatingPanel`** — 不抢焦点
- **`ignoresMouseEvents` 动态切换** — 收起态点击穿透到菜单栏
- **全局鼠标事件监听 throttle 50ms** — 避免重渲染
- **boot 动画**（启动后 300ms 展开 + 1000ms 后收起）
- **`level = .mainMenu + 3`** 收起态，`.popUpMenu` 展开态
- **`collectionBehavior = [.canJoinAllSpaces, .stationary, ...]`**

### 3. API 合约

```swift
// NotchModule.swift
@MainActor
@Observable
final class NotchModule {
    static let shared = NotchModule()
    private(set) var isActive: Bool = false
    private var controllers: [NotchWindowController] = []

    func activate() { /* create controllers for each screen */ }
    func deactivate() { /* tear down */ }
}

// NotchViewModel.swift
@MainActor
@Observable
final class NotchViewModel {
    enum Status { case closed, opened, popping }
    enum OpenReason { case click, hover, notification, boot, unknown }

    private(set) var status: Status = .closed
    private(set) var openReason: OpenReason = .unknown
    var isHovering: Bool = false

    let geometry: NotchGeometry
    let hasPhysicalNotch: Bool
    let screenID: String

    func notchOpen(reason: OpenReason)
    func notchClose()
    func performBootAnimation()
}
```

## 验收标准（必须全绿才能进入 P2）

### A. 构建 / 测试

- [ ] `swift build` 0 warning, 0 error
- [ ] `swift test` 全部通过（现有 186 + 新增 Notch 测试 ≥ 4）
- [ ] 新增文件全部 ≤ 400 行
- [ ] 无 `print()`，用 `os.Logger`

### B. 运行时

- [ ] App 启动后 300ms，Notch 展开成小 panel 约 1 秒后收起（boot 动画）
- [ ] 鼠标悬停刘海区域 ≤ 200ms 自动展开
- [ ] 鼠标移开 ≤ 500ms 自动收起
- [ ] 点击刘海 → 展开；点击面板外 → 收起 + 点击穿透到下方
- [ ] 收起态下点击菜单栏图标/其他 app 完全正常
- [ ] 多屏（内建 + 外接）：只在内建屏（有物理刘海的）显示

### C. UI 截图（放到 `.island_merge/screenshots/actual/phase-1/`）

| 文件名 | 要求 |
|-------|------|
| `01-boot-collapsed.png` | 启动后收起态，刘海区域完全透明 |
| `02-hover-expanded.png` | hover 展开，显示 "Hello Notch" 占位文字 |
| `03-click-expanded.png` | 点击后展开同 02，但更明显（focus） |
| `04-click-outside-closes.png` | 面板外点击后收起 |

### D. 回归（旧功能不能炸）

- [ ] Apu 精灵仍然正常出现（P1 还没引入 ModeManager，两者可能同时显示，这是允许的）
- [ ] BreakScheduler 每 20 分钟倒计时正常
- [ ] Dashboard 能打开
- [ ] Preferences 能打开
- [ ] 全部 186 个旧测试仍通过

## 实现 Agent 工作指引

1. 先读 `mio-guard/ClaudeIsland/` 下的 7 个核心文件（README 里映射表）
2. 在 `EyeGuard/Sources/Notch/` 下按上述目录逐文件创建
3. 每写完一个文件：立即 `swift build` 检查
4. 全部写完：`swift test`
5. 手动跑 app，截 4 张图存到 `.island_merge/screenshots/actual/phase-1/`
6. 填写 `review_log/YYYY-MM-DD-HHMM-phase-1.md`（模板见 `validation/validation-protocol.md`）
7. 把 git commit 推到 main（单次 commit 就够了，消息：`feat(notch): phase 1 — notch shell scaffolding`）

## 故障 / 回滚

如果任何验收项 ❌：
- 不要 force-merge，停下来在 `review_log/` 记录失败原因
- PM（Claude）会在下次 30 分钟 review 时诊断并给出修复指令
- 如果阻塞超过 2 个 review 周期（1 小时），删除 `EyeGuard/Sources/Notch/` 并回滚 `App/` 改动，重新设计

## 时间预算

- 实现：3-4 小时
- Review + 修复：1-2 小时
- 总计：≤ 1 天
