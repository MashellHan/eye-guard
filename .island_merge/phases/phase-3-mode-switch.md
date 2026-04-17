# Phase 3 — 精灵 ↔ Notch 互斥切换

> **目标**：加入 ModeManager，允许用户在 **Apu 精灵模式** 和 **Notch 灵动岛模式** 之间切换。同一时刻只显示一种。切换带 spring 动画，状态持久化到 UserDefaults。

## 前置

- Phase 1 + Phase 2 全部 ✅
- Apu 精灵、BreakScheduler 保持不变

## 交付物

### 新增源码

```
EyeGuard/Sources/App/
├── ModeManager.swift           # @Observable, AppMode(apu/notch), UserDefaults
└── AppModeCoordinator.swift    # 监听 ModeManager，激活/停用 NotchModule 或 Apu

EyeGuard/Sources/Mascot/
└── ApuMascotModule.swift       # 重构现有 Apu 出现/消失为 module.activate/deactivate
```

### 修改

- `EyeGuard/Sources/App/PreferencesView.swift` 加"显示模式"分段控件
- StatusItem 右键菜单加"切换到 Notch / 切换到精灵"
- `AppDelegate`（或 EyeGuardApp）：构造 `ModeManager` + `AppModeCoordinator`

## 设计

### AppMode

```swift
enum AppMode: String, CaseIterable, Identifiable, Sendable {
    case apu = "apu"       // 精灵模式（原生）
    case notch = "notch"   // 灵动岛模式
    var id: String { rawValue }
    var localizedName: String { ... }
    var icon: String { ... }  // SF Symbol
}
```

### 切换逻辑

```
currentMode 变化
  ├─ .apu  → NotchModule.deactivate() + ApuMascotModule.activate()
  └─ .notch → ApuMascotModule.deactivate() + NotchModule.activate()
```

### 切换动画

- Apu → Notch：Apu 精灵 `.scale(0).opacity(0)` spring 淡出；Notch boot 动画同时进入
- Notch → Apu：Notch 展开 + 收起再渐出；Apu 从菜单栏下方 spring 弹出

### 持久化

- 默认 `.apu`（向后兼容现有用户）
- Key: `eyeguard.displayMode`
- 切换立即 `UserDefaults.synchronize()`

## 验收

### A. 构建 / 测试

- [ ] `swift test` 所有通过
- [ ] 新增 ModeManagerTests（8+ 测试，覆盖默认值/切换/持久化/重启恢复）

### B. 运行时

- [ ] 默认启动 = Apu 精灵模式（不破坏现有用户）
- [ ] Preferences 切换到 Notch → Apu 消失 + Notch 出现
- [ ] 关闭 app 再启动 → 保持 Notch 模式
- [ ] 重复切换 10 次不泄漏窗口 / 不崩溃
- [ ] 切换动画流畅（60fps，看视觉无卡顿）

### C. UI 截图 / 录屏

- `01-mode-apu.png`
- `02-mode-notch.png`
- `03-switch-animation.mov`（2 秒录屏）
- `04-preferences-mode-picker.png`

### D. 回归

- P1 + P2 全部项重跑 ✅
- 186 旧测试通过
