# Backlog

> 合并 `docs/bugs.md` + 已知技术债。按优先级排，从上往下做。
> 修的时候用 `/feature <描述>` 走完整流程。

更新时间：2026-04-23

---

## P0 — 基础设施（先补，否则 tester 形同虚设）

（已完成，见底部 ## 已完成）

---

## P0 — 核心功能失效

（已完成，见底部 ## 已完成）

## P1 — 用户体验破坏

### B2. Break 结束语音重复播报 2 次（bugs.md #2）
- 订阅没去重 / SwiftUI view 重建导致重复触发
- 加幂等保护或正确取消订阅

### B5. 调查稳态 idle CPU 超阈（新发现 2026-04-23）
- task `20260423-1456-debugtrigger` iter3 tester 确认：30s 稳态 CPU mean 3.01%，last-10s mean 3.45%，13/30 样本 > 3%（阈值 3%）
- 启动后 ~12s 还有 16-24% 的孤立尖峰
- launch_ms 96ms 完全没问题；RSS 85MB 也 OK；只有 CPU 持续超
- 可能位置：`ActivityMonitor.swift`（CGEventTap 高频）、menubar refresh timer (1Hz)、AppModeCoordinator init、ModeManager
- 修复方向：用 Instruments time profile 找 hot path；考虑 menubar 倒计时改成 widget refresh + 1s timer 用 DispatchSourceTimer
- 验收：`/perf-check` 跑出 mean < 3% / max < 10%（去除启动尾）

---

## P2 — 技术债（来自 review warning）

### W1. DRY: breakdown 视图重复
- `breakdownRow` + `breakdownPopoverContent` 在 MenuBar 和 Notch 各一份
- 抽到共享 view（注意架构 R1：业务逻辑不能反向依赖 view，新 shared view 放 `EyeGuard/Sources/UI/Shared/` 之类）

### W2. `EyeGuardExpandedView` 高度测量
- 测量循环没有上界，可能死循环
- `private(set)` 违规
- 加 max iteration + 修可见性

### W3. `disciplineRecoveryPoints = 3` 缺医学引用
- 违反 R6（医学常量必须标 source）
- 补 AAO/OSHA/NIOSH 引用，否则改成可配置 + TODO

### W4. `qualityExplanation` 漂移风险
- 文案与 `calculateBreakQuality` 是两份逻辑
- 加单测确保两边同步，或重构成单一 source of truth

---

## P3 — Nit

- **N1** MenuBar `Binding.get` 里多余的 `hasDetail` 判断
- **N2** `.help()` 移除后丢了 VoiceOver hint → 加 `.accessibilityHint`
- **N3** `AppColors.popoverBackground` 已定义但没用 → 用上或删

---

## 已完成

- popover 透明度修复（背景换 windowBackgroundColor）
- HealthScore 可解释 breakdown + click-to-open popover
- 多 agent harness（dev / reviewer / tester + /feature skill）
- **I1** DebugTrigger 实现支持 test-matrix 全部 Tier A/B + Tier C 入口（task `20260423-1456-debugtrigger`，2026-04-23）
  - 完成于 2026-04-23，commit 见 git log，test report `.agent_workspace/tests/20260423-1456-debugtrigger/report.md` (iter3)
  - 注：tester iter3 verdict=FAIL 是因 idle CPU 超阈（已拆为 B5），DebugTrigger 自身的 mascot 5 状态可分 + menubar popover 渲染 + 全 15 state 截图都 PASS
- **B3** Notch take-a-break 无响应 + 倒计时卡 00:00（task `20260423-1649-notch-takebreak`，2026-04-23）
  - 完成于 2026-04-23，commit `2fdcf5e`，test report `.agent_workspace/tests/20260423-1649-notch-takebreak/report.json`
  - 修复：BreakScheduler.requestManualBreak 统一 manual-break 入口（mascot/menubar/notch 三路共用），updateNextBreak 在 overdue 时把 timeUntilNextBreak clamp 到 0
  - 注：tester PASS 但 3 条 regression 单测被列为 MISSING_COVERAGE warning（dev.md/tester.md 责任分工争议，留作后续 chore）；UI 截图因 Screen Recording 权限缺失被 skip，code path 由 reviewer 验证
- **B4** "开始眼保健操"按钮无响应（task `20260423-1730-exercise-button`，2026-04-23）
  - 完成于 2026-04-23，commit `2f2874a`，test report `.agent_workspace/tests/20260423-1730-exercise-button/report.json`
  - 修复：抽出共享 `ExercisePresenter` 接管全屏 exercise window；EyeGuardApp.init 注册一次 `.startExercisesFromBreak` observer（Notch 模式不再无响应）；BreakOverlayView Tier 2 按钮改 post notification（不再塞进 320pt 浮窗）
  - reviewer & tester 全 PASS，0 critical 0 warning
- **B1** Break overlay 白底文字不可读（task `20260423-1810-overlay-contrast`，2026-04-23）
  - 完成于 2026-04-23，commit `54c33c0`，test report `.agent_workspace/tests/20260423-1810-overlay-contrast/report.json`
  - 修复：Tier 2 加 black scrim (0.35) + 强制 white text，healthScore chip 背景换 .black.opacity(0.25)；Tier 3 不动
  - reviewer PASS (1 warn: icon 还是 .blue), tester PASS (UI 截图因 infra SKIPPED, code review 已确认)
