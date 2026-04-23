# Backlog

> 合并 `docs/bugs.md` + 已知技术债。按优先级排，从上往下做。
> 修的时候用 `/feature <描述>` 走完整流程。

更新时间：2026-04-23

---

## P0 — 基础设施（先补，否则 tester 形同虚设）

### I1. 实现 `EyeGuard/Sources/App/DebugTrigger.swift`
- tester 截图依赖 `DEBUG_UI_STATE` env var 触发指定 UI 状态
- 不实现 → 所有 UI 截图测试都标 `skipped`，UI bug 修了也验不了
- 至少支持 `test-matrix.md` 里列的所有 state
- ⚠️ 尝试于 2026-04-23 (task `20260423-1456-debugtrigger`)：dev iter3 实现完成（review PASS，build/test 全绿），但 tester iter2 截图覆盖丢失（全黑 PNG）+ 偶发 idle CPU 尖峰，**未达 PASS**。代码很可能可用，但需要新一轮跑 tester 在干净环境验证。详见 `.agent_workspace/tests/20260423-1456-debugtrigger/report.json` (iter2)、`reviews/20260423-1456-debugtrigger-r3.md`

---

## P0 — 核心功能失效

### B3. Notch take-a-break 无响应 + 倒计时卡 00:00（bugs.md #3）
- 点击 island 上 take-a-break 按钮没反应
- 倒计时跑到 00:00 后不进入 break
- 怀疑 `EyeGuardDataBridge` 事件没透传 / transition 被某条件挡住

### B4. "开始眼保健操"按钮无响应（bugs.md #4）
- 点击无任何反馈
- 定位 action handler / 路由

---

## P1 — 用户体验破坏

### B1. Break overlay 白底文字不可读（bugs.md #1）
- WCAG AA < 4.5:1
- `EyeGuard/Sources/Notifications/BreakOverlayView.swift`
- 修复方向：降低背景透明度 / scrim / 文字描边
- 验收：白底/深底/彩色壁纸三种背景文字都清晰
- I1 完成后 tester 的 `overlay-tier2-micro` / `overlay-tier3-mandatory` 自动覆盖

### B2. Break 结束语音重复播报 2 次（bugs.md #2）
- 订阅没去重 / SwiftUI view 重建导致重复触发
- 加幂等保护或正确取消订阅

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
