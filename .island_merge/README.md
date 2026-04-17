# Island Merge — Eye Guard × MioIsland

## 目标

把 **MioIsland**（`MashellHan/mio-guard`，原 `MioMioOS/MioIsland`）的 **Dynamic Notch（灵动岛）UX/UI/动画/交互机制** rewrite 到当前 Eye Guard SPM 项目中，成为一个新的**显示模式**，与现有的**精灵模式（Apu Mascot）**共存切换。

**主旨不变**：仍然是一个护眼提醒应用。Notch 只是一个新的**展示层**，底层 BreakScheduler / ActivityMonitor / Exercises / HealthScore 等业务逻辑完全复用。

## 设计原则

1. **不搞新的 Xcode 项目** — 继续用 SPM（`swift build` 一键跑）
2. **不复制代码** — 从 Mio 学架构和实现思路，rewrite 到适配 Eye Guard 现有架构的代码
3. **不破坏现有功能** — 精灵模式、BreakScheduler、Dashboard、Preferences 全部保留
4. **模式互斥** — 同一时刻只显示一种：Apu 精灵 OR Notch 灵动岛（后续可选支持 Dual）
5. **渐进交付** — 分 5 个 Phase，每个 Phase 单独可跑、可验证、可 rollback
6. **验证驱动** — 每个 Phase 有明确的验收标准、自动化检查、UI 截图对比

## Phase 总览

| Phase | 目标 | 交付 | 验收 | 阻塞 |
|-------|------|------|------|------|
| **P1** | Notch 空壳跑通 | 透明 NSPanel + boot 动画 + hover/click 开合 | UI 截图 3 张 + 单元测试 4+ 个 | 无 |
| **P2** | 护眼数据注入 | 收起态显示用眼时间/色点，展开态显示评分/倒计时 | UI 截图 + 数据链路测试 | P1 |
| **P3** | 精灵 ↔ Notch 互斥切换 | ModeManager + 右键菜单 + spring 动画 | 切换动画录屏 + 持久化测试 | P2 |
| **P4** | Notch 驱动休息流 | pop 通知 + 打字动画 + 进入眼保健操 | 完整休息周期 E2E | P3 |
| **P5** | 打磨 + 发布 | 多屏、hover 速度、位置微调、暗色、图标 | 全量回归 + Homebrew | P4 |

## 目录结构

```
.island_merge/
├── README.md                      ← 本文件（master plan）
├── phases/
│   ├── phase-1-notch-shell.md     ← Phase 1 详细设计 + 验收
│   ├── phase-2-data-injection.md
│   ├── phase-3-mode-switch.md
│   ├── phase-4-break-flow.md
│   └── phase-5-polish.md
├── validation/
│   ├── validation-protocol.md     ← Agent 验证流程手册
│   ├── ui-checklist.md            ← UI 截图对比清单
│   └── regression-matrix.md       ← 每个 Phase 的回归矩阵
├── review_log/
│   └── YYYY-MM-DD-HHMM-phaseN.md  ← 每次 30 分钟 review 的结果
└── screenshots/
    ├── expected/                  ← 期望的 UI（参考 Mio）
    └── actual/                    ← Agent 实现后的截图
```

## 工作模式

1. **PM（本 Claude）**：编写 Phase 规格、验收标准、review 实现 Agent 的代码与截图
2. **实现 Agent**：按 `phase-N.md` 规格实现，必须更新 `review_log/` + 产出截图
3. **定期 review**：每 **30 分钟** 由 cron 触发 PM 运行验证流程（见 `validation-protocol.md`）
4. **Phase gate**：只有当前 Phase 的所有验收项 ✅ 才能启动下一 Phase

## 当前状态

- **启动时间**: 2026-04-17
- **当前 Phase**: **P3（待实现）** — P2 已完成 ✅ (见 `review_log/2026-04-17-1645-phase-2-impl.md`)
- **上游仓库**:
  - Eye Guard SPM: `eye-guard/` (当前目录)
  - Mio 参考: `../mio-guard/ClaudeIsland/`

## 源码参考映射（Mio → Eye Guard 新模块）

| Mio 源文件 | Eye Guard 目标 | 状态 |
|-----------|---------------|------|
| `Core/NotchGeometry.swift` | `EyeGuard/Sources/Notch/Geometry/NotchGeometry.swift` | P1 |
| `Core/Ext+NSScreen.swift` | `EyeGuard/Sources/Notch/Geometry/NSScreen+Notch.swift` | P1 |
| `Core/NotchHardwareDetector.swift` | `EyeGuard/Sources/Notch/Geometry/NotchHardwareDetector.swift` | P1 |
| `Core/NotchViewModel.swift` | `EyeGuard/Sources/Notch/NotchViewModel.swift` | P1 |
| `UI/Window/NotchWindow.swift` | `EyeGuard/Sources/Notch/Window/NotchPanel.swift` | P1 |
| `UI/Window/NotchWindowController.swift` | `EyeGuard/Sources/Notch/Window/NotchWindowController.swift` | P1 |
| `UI/Window/NotchViewController.swift` | `EyeGuard/Sources/Notch/Window/NotchHostingController.swift` | P1 |
| `UI/Components/NotchShape.swift` | `EyeGuard/Sources/Notch/Views/NotchShape.swift` | P1 |
| `UI/Views/NotchView.swift` (1313 行) | `EyeGuard/Sources/Notch/Views/NotchContainerView.swift` (精简) | P1 |
| `Events/EventMonitors.swift` | `EyeGuard/Sources/Notch/Events/EventMonitors.swift` | P1 |
| `UI/Views/EyeGuard/EyeGuardCollapsedContent.swift` | `EyeGuard/Sources/Notch/Views/CollapsedContent.swift` | P2 |
| `UI/Views/EyeGuard/EyeGuardNotchView.swift` | `EyeGuard/Sources/Notch/Views/ExpandedEyeGuardView.swift` | P2 |
| `Core/ModeManager.swift` | `EyeGuard/Sources/App/ModeManager.swift` | P3 |

**不移植**：Chat、Plugin Store、Codex/Claude Session、Tmux、PairPhone、SoundManager、DualMode 等与护眼无关的内容。

## 下一步

1. 读 `phases/phase-1-notch-shell.md`
2. 启动实现 Agent 按规格实现
3. PM 每 30 分钟运行 `validation/validation-protocol.md` 流程
