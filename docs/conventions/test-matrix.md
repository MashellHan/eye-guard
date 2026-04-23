# 测试矩阵 — 模块到测试范围映射

> tester 据此决定**哪些 UI 状态需要截图、哪些性能指标需要采样**。
> lead 据此根据 `git diff --name-only` 计算本次任务的测试范围。

## 触发规则

```
本次任务 test_scope = ⋃ {match_rules(file) : file ∈ git_diff}
                   + 始终包含 baseline (build + unit + perf-launch)
```

如果 test_scope 为空（比如只改文档），仍跑 baseline。

## 路径模式 → 测试集合

| 改动文件路径模式 | 触发的 UI 截图 | 触发的性能项 | 触发的单测 |
|---|---|---|---|
| `EyeGuard/Sources/App/MenuBarView.swift` | `menubar-popover`、`menubar-popover-mascot-mode`、`menubar-popover-notch-mode` | launch、popover-open-cpu | — |
| `EyeGuard/Sources/App/EyeGuardApp.swift` | 所有 baseline UI | launch（严格） | — |
| `EyeGuard/Sources/App/AppDelegate.swift` | 所有 baseline UI | launch（严格） | — |
| `EyeGuard/Sources/Mascot/**` | `mascot-idle`、`mascot-concerned`、`mascot-alerting`、`mascot-resting`、`mascot-celebrating` | mascot-idle-cpu | `MascotTests` |
| `EyeGuard/Sources/Notch/**` | `notch-collapsed`、`notch-expanded`、`notch-pop-banner` | notch-hover-cpu | `NotchTests` |
| `EyeGuard/Sources/Notifications/BreakOverlayView.swift` | `overlay-tier2-micro`、`overlay-tier2-macro` | overlay-render-cpu | — |
| `EyeGuard/Sources/Notifications/FullScreenOverlayView.swift` | `overlay-tier3-mandatory` | overlay-render-cpu | — |
| `EyeGuard/Sources/Notifications/**` (其它) | `overlay-tier2-micro`、`overlay-tier3-mandatory` | overlay-render-cpu | `NotificationsTests` |
| `EyeGuard/Sources/Exercises/**` | `exercise-focus-shifting`、`exercise-figure-8`、`exercise-circle`、`exercise-distance`、`exercise-palming` | exercise-anim-cpu | `ExercisesTests` |
| `EyeGuard/Sources/Dashboard/**` | `dashboard-today`、`dashboard-history`、`dashboard-breakdown` | dashboard-render-cpu | `DashboardTests` |
| `EyeGuard/Sources/Reporting/**` | `report-window` | — | `ReportingTests`、`HealthScoreTests` |
| `EyeGuard/Sources/App/PreferencesView.swift` | `prefs-general`、`prefs-reminder-modes`、`prefs-sounds` | — | — |
| `EyeGuard/Sources/Scheduling/**` | — | — | `SchedulingTests`、`BreakSchedulerTests` |
| `EyeGuard/Sources/Monitoring/**` | — | idle-cpu | `MonitoringTests` |
| `EyeGuard/Sources/Audio/**` | — | — | `AudioTests` |
| `EyeGuard/Sources/AI/**` | — | — | `AITests` |
| `EyeGuard/Sources/Analysis/**` | — | color-sample-cpu | `AnalysisTests` |
| `EyeGuard/Sources/Models/**` | — | — | **全部单测**（基础类型变动影响大） |
| `EyeGuard/Sources/Protocols/**` | — | — | **全部单测** |
| `EyeGuard/Sources/Persistence/**` | — | — | `PersistenceTests`（含 migration） |
| `EyeGuard/Sources/Tips/**` | `mascot-idle` (检查 speech bubble) | — | `TipsTests` |
| `EyeGuard/Sources/Utils/Colors.swift` | **全部 baseline UI**（颜色全局影响） | — | — |
| `EyeGuard/Sources/Utils/Constants.swift` | — | launch | **全部单测** |
| `EyeGuard/Sources/Utils/**` (其它) | — | — | `UtilsTests` |
| `EyeGuard/Tests/**` | — | — | 仅跑这些被改的测试 + 它们覆盖的模块 |
| `Package.swift` | 所有 baseline UI | launch | **全部单测** |
| `CLAUDE.md` / `docs/**` / `.claude/**` | — | — | — |

## 集合定义

### Baseline UI（最小集，**永远跑**）
- `menubar-popover`（默认 Apu Mascot 模式）
- `mascot-idle`

### Baseline 性能（最小集，**永远跑**）
- `launch`（启动时间）
- `idle-rss`（启动后 10s 稳态 RSS）
- `idle-cpu`（启动后 10s 稳态 CPU）

### Daily Full UI（每日定时跑）
所有上表出现过的 UI 截图集合的并集，加上 `prefs-*` 全部子页。

## 性能阈值（硬门槛，超过即 FAIL）

| 指标 | 阈值 | 来源 |
|---|---|---|
| 启动时间 (launch_time_ms) | **< 2000 ms** | 用户约定 2026-04-23 |
| 常驻内存 RSS (idle_rss_mb) | **< 100 MB** | 用户约定 2026-04-23 |
| 稳态 CPU (idle_cpu_pct) | **< 3%** | 用户约定 2026-04-23（推测，若错请改） |
| 峰值 CPU (peak_cpu_pct) | < 25% | 临时值，待用户确认 |
| 文件描述符 (fd_count) | < 200 | 经验值 |
| 线程数 (thread_count) | < 30 | 经验值 |
| 虚拟内存 VSZ | < 2 GB | 经验值 |

## 备注

- 任何 UI 截图的"点击/悬停"等触发动作，依赖 **`EyeGuard/Sources/App/DebugTrigger.swift`** 提供的命令行 / 环境变量入口（见该文件文档）
- 性能采样在 baseline UI 启动后，等 3 秒进入稳态，然后每秒采样 10 次取均值
- 阈值修改请在本文件改，不要散落到 tester 的 SOP

### DebugTrigger 当前支持的 `DEBUG_UI_STATE` 状态

启动方式：`DEBUG_UI_STATE=<state> open EyeGuard.app`。激活后 scheduler 自动暂停，需重启才能恢复正常调度。

**Tier A（baseline + bug 重现，已实现）**
- `menubar-popover`
- `mascot-idle`
- `overlay-tier2-micro`、`overlay-tier2-macro`
- `overlay-tier3-mandatory`

**Tier B（覆盖率扩展，已实现）**
- `menubar-popover-mascot-mode`、`menubar-popover-notch-mode`
- `mascot-concerned`、`mascot-alerting`、`mascot-resting`、`mascot-celebrating`
- `notch-collapsed`、`notch-expanded`、`notch-pop-banner`
- `dashboard-today`
- `report-window`
- `prefs-general`

**Tier B 部分支持（仅父窗口，子 tab 路由 TBD，backlog `I1-tier-C`）**
- `dashboard-history`、`dashboard-breakdown` — DebugTrigger 显式 log error 并 return；tester 标 `skipped, reason=debug_trigger_unsupported`
- `prefs-reminder-modes`、`prefs-sounds` — 同上

**Tier C（仅入口，子帧待 backlog `I1-tier-C`）**
- `exercise-focus-shifting`、`exercise-figure-8`、`exercise-circle`、`exercise-distance`、`exercise-palming`

未列出的 state（含上述部分支持的 state）→ tester 标 `skipped`, `reason=debug_trigger_unsupported`。
