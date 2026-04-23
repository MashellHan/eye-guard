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

（已完成，见底部 ## 已完成）

---

## P2 — 技术债（来自 review warning）

（已完成，见底部 ## 已完成）

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
- **W4** `qualityExplanation` 与 `calculateBreakQuality` 漂移风险（直接修，无 plan/test，2026-04-23）
  - 完成于 2026-04-23
  - 修复：抽 `breakQualityBaseMaxPoints = 6`、`breakQualityExerciseBonusPoints = 4` 到 EyeGuardConstants（doc 强制 base+bonus = max）；新增 `averageBreakQuality(_:)` 私有 helper，两个函数共用 → 消除两份独立的 avg-quality 计算公式；顺手把 disciplineExplanation 残留的 `streak / 3` magic 也换成 `disciplineRecoveryStreakThreshold` 常量（W3 后续清理）
  - swift build + swift test 233/233 通过
- **W3** `disciplineRecoveryPoints = 3` 缺医学引用（直接修，无 plan/test，2026-04-23）
  - 完成于 2026-04-23
  - 修复：抽 magic `3` 到 `EyeGuardConstants.disciplineRecoveryStreakThreshold`，doc 明确标注**非医学常量**（AAO/OSHA/NIOSH 不规定 streak 奖励，仅规定休息频率/时长），是 gamification 启发；HealthScoreCalculator 用具名常量；TODO 留作未来 user-tunable
  - swift build + swift test 233/233 通过；非 R6 违规（R6 仅约束医学常量），但 magic number 已消除
- **W2** `EyeGuardExpandedView` 高度测量（task `20260423-2230-height-measurement`，2026-04-23）
  - 完成于 2026-04-23，commit `2946415`，test report `.agent_workspace/tests/20260423-2230-height-measurement/report.json`
  - 修复：`measuredEyeGuardHeight` 改 `private(set)`；新增 `updateMeasuredEyeGuardHeight(_:)` setter，0.5pt diff guard + 500ms/10-write 滑动窗口节流（超限 `Log.notch.warning`）；view 不再直接写 viewModel 属性
- **W1** DRY breakdown 视图重复（task `20260423-2130-breakdown-dry`，2026-04-23）
  - 完成于 2026-04-23，commit `eedf647`，test report `.agent_workspace/tests/20260423-2130-breakdown-dry/report.json`
  - 修复：抽 `EyeGuard/Sources/UI/Shared/BreakdownRowView.swift`，配 `BreakdownTheme` enum (.menubar/.notch) 注入字体/颜色/宽度差异；MenuBarView + HealthScoreSection 调用方改用共享组件，删旧 helper + state；R1 不破（共享 view 只读 ScoreComponent）
  - 视觉 parity 验证通过；idle CPU 2.11%（B5 不退化）
- **B5** 稳态 idle CPU 超阈（task `20260423-2030-idle-cpu`，2026-04-23）
  - 完成于 2026-04-23，commit `9975646`，test report `.agent_workspace/tests/20260423-2030-idle-cpu/report.json`
  - 修复：(1) Mascot 鼠标追踪 10Hz Task.sleep poll → global NSEvent mouse-moved 事件监听（peek-mode 面板大半时间在屏外，event monitor > NSTrackingArea）；(2) Mascot bubble monitor 2Hz poll → `showBubble` didSet 回调；(3) MenuBar + Notch 倒计时 Text 套 `TimelineView(.periodic by: 1.0)`，把每秒 invalidation 隔离在 Text 节点内
  - 结果：30s 稳态 mean 3.01% → **2.16%**（target <3%），last-10s mean 3.45% → 1.57%（-55%），>3% 样本 13/30 → 7/30
  - 留 2 个 W 级 follow-up（mouse monitor 未 throttle、bubble didSet 初值同步）— tester 标 nice-to-have
- **B6** Break overlay 弹出后倒计时 ~3s 就自动退出（task `20260423-1945-overlay-3s-dismiss`，2026-04-23）
  - 完成于 2026-04-23，commit `e8ea9a6`，test report `.agent_workspace/tests/20260423-1945-overlay-3s-dismiss/report.json`
  - 修复：FullScreenOverlayView/BreakOverlayView 的 `startCountdownTimer` 首行 `timer?.invalidate(); timer = nil` 防止 NSHostingView 重复 onAppear 叠加 N 个 Timer（N×1Hz → 20s 在 ~3s 跑完）；FullScreenOverlayView 加 onAppear re-entry guard；加 per-instance UUID 诊断日志
  - reviewer & tester 全 PASS（screenshot 实拍 4s 后 mandatory 倒计时还在 14:57，证明 1Hz 真实速率），UI baseline 4 张因 screencapture 窗口定位 infra flake 计为 SKIPPED_INFRA
- **B2** Break 结束语音重复播报 2 次（task `20260423-1900-tts-dup`，2026-04-23）
  - 完成于 2026-04-23，commit `0cee483`，test report `.agent_workspace/tests/20260423-1900-tts-dup/report.json`
  - 修复：FullScreenOverlayView 加 `isPrimary` 标志 + `hasCompleted` 守卫；OverlayWindow 按 NSScreen.main 选 primary，secondary 屏不发声不触发 onBreakTaken
  - reviewer & tester 全 PASS，0 critical 0 warning
