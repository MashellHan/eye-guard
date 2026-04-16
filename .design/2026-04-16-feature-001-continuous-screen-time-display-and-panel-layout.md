# Feature Design: Continuous Screen Time Display & Panel Layout Optimization

**Date:** 2026-04-16
**Status:** ✅ Done (`b949609`, `5c90f13`, `0c37d2b`)
**Priority:** P1

---

## 1. Continuous Screen Time Display (连续使用屏幕时间)

### What
在 MenuBarView 主面板显著位置展示「你已连续使用屏幕 XX 时间」，锁屏后自动 reset。

### Why
用户最关心的实时指标是「我到底连续用了多久」，当前 `timerSection` 已有 `currentSessionDuration` 但标题是 "Current Session"，语义不够直观，且没有强调「连续」的含义。

### Design

#### UI 位置
在 `headerSection` 和 `healthScoreSection` 之间插入新的 `continuousScreenTimeSection`，作为面板最醒目的信息。

#### UI 样式
```
┌─────────────────────────────────────────┐
│  🖥  已连续使用屏幕                       │
│       2h 35m                            │
│  ████████████████░░░░  (progress bar)   │
│  下次休息: 微休息 还剩 4m 32s             │
└─────────────────────────────────────────┘
```

- 大字体 monospaced 显示时间（`.system(.title, design: .monospaced)`）
- 进度条显示距离下次休息的进度
- 颜色分级：
  - < 20min: `.green`
  - 20-45min: `.blue`
  - 45-60min: `.orange`
  - > 60min: `.red` + 闪烁动画
- 中文文案：「已连续使用屏幕」（考虑 Locale 支持英文 "Continuous screen time"）

#### 锁屏 Reset 逻辑
**已有基础设施**：`ActivityMonitor.handleScreenUnlocked()` 已经会调用 `handleActivityResumed()`，其中 `currentSessionDuration = 0`。

需要验证链路：
1. `ScreenLockObserver` 收到 `com.apple.screenIsUnlocked`
2. → `ActivityMonitor.handleScreenUnlocked()` 
3. → `BreakScheduler.handleActivityResumed()` → `currentSessionDuration = 0`

**注意**：检查 `BreakScheduler` 是否监听了 `ActivityMonitor` 的 unlock 事件。如果没有，需要在 `BreakScheduler.startScheduling()` 中注册回调。

### Implementation Notes
- 数据源：`scheduler.currentSessionDuration`（已存在）
- 复用现有 `TimeFormatting.formatTimerDisplay()` 
- 移除或简化原有的 `timerSection`，避免重复信息

---

## 2. Generate Report 与 Dashboard 按钮分离

### What
当前 `reportSection` 和 `footerSection`（含 Dashboard 按钮）视觉上分开但布局不合理。Generate Report 按钮孤立在一行，Dashboard 和 Preferences/Quit 挤在一行。

### Design

#### 新布局方案
将面板底部按钮区域重组为两行：

```
┌─────────────────────────────────────────┐
│  [📊 Dashboard]     [📄 Generate Report] │  ← 功能操作行
│──────────────────────────────────────────│
│  [⚙ Preferences]              [✕ Quit]  │  ← 系统操作行
└─────────────────────────────────────────┘
```

- Dashboard 和 Generate Report 同级并排，作为「数据查看」类操作
- Preferences 和 Quit 另起一行，作为「系统控制」类操作
- 两个功能按钮使用 `.bordered` style，视觉权重一致

### Implementation
- 删除 `reportSection`
- 重构 `footerSection` 为 `actionSection` + `footerSection`

---

## 3. Panel 加宽

### What
当前面板 `frame(width: 300)`，内容较密集。

### Design
- 宽度从 300 → 360
- 给 health score breakdown 和 stats 更多呼吸空间
- 考虑到 macOS menu bar popover 标准宽度通常 280-380，360 仍在合理范围

### Implementation
- `MenuBarView.body` 中 `.frame(width: 360)`

---

## 4. 变更文件清单

| File | Change |
|------|--------|
| `Sources/App/MenuBarView.swift` | 新增 `continuousScreenTimeSection`，重构 `timerSection`/`reportSection`/`footerSection`，宽度改 360 |
| `Sources/Scheduling/BreakScheduler.swift` | 验证/补充 screen unlock → session reset 链路 |
| `Tests/BreakSchedulerTests.swift` | 添加锁屏 reset 行为测试 |

## 5. Acceptance Criteria

- [ ] Panel 显示「已连续使用屏幕 Xh Xm」，实时更新
- [ ] 锁屏后解锁，计时器 reset 为 0
- [ ] Dashboard 和 Generate Report 按钮并排显示
- [ ] Preferences 和 Quit 单独一行
- [ ] Panel 宽度 360pt
- [ ] 现有测试通过，新增锁屏 reset 测试
