# Phase 2 — 护眼数据注入 Notch

> **目标**：让 Notch 展示真实的护眼数据。收起态显示连续用眼时间 + 状态色点，展开态显示健康评分 + 下次休息倒计时 + 立即休息按钮。复用现有 `BreakScheduler`，不重写业务逻辑。

## 前置

- Phase 1 全部 ✅
- BreakScheduler、HealthScoreCalculator、ActivityMonitor 保持不变

## 交付物

### 新增源码

```
EyeGuard/Sources/Notch/Views/EyeGuard/
├── EyeGuardCollapsedContent.swift    # 收起态：色点 + 小文字
├── EyeGuardExpandedView.swift        # 展开态：主面板
├── ContinuousTimeSection.swift       # 连续用眼大字体 + 进度条
├── HealthScoreSection.swift          # 今日健康评分
├── NextBreakSection.swift            # 下次休息倒计时
└── BreakNowButton.swift              # 立即休息
```

### 修改

- `NotchViewModel.swift` 增加 `contentType` 枚举（目前只有 `.eyeGuard`）
- `NotchContainerView.swift` switch over contentType 分发
- **新增桥接**：`EyeGuard/Sources/Notch/Bridges/EyeGuardDataBridge.swift`
  - `@Observable`，持有 `BreakScheduler` 引用
  - 暴露 `continuousTime`, `healthScore`, `nextBreakIn`, `isInBreak` 等只读属性
  - 每秒通过 `withObservationTracking` 更新

## 设计

### 色点状态

| 连续用眼 | 颜色 | SF Symbol |
|---------|------|-----------|
| < 10 min | `.green` | `circle.fill` |
| 10–15 min | `.yellow` | `circle.fill` |
| 15–20 min | `.orange` | `circle.fill` |
| ≥ 20 min | `.red` | `exclamationmark.circle.fill` |
| 休息中 | `.blue` | `eye.slash.fill` |

### 收起态布局（左右翼）

```
 [·green]  00:12     [eye]
 └刘海左翼────────────右翼┘
```

### 展开态布局

```
┌──────────────────────────────┐
│  🟢 连续用眼                   │
│     12:34 / 20:00 ━━━━━━━━━━━ │
│                                │
│  健康评分: 85 / 100            │
│  下次休息: 07:26              │
│                                │
│     [立即休息]                │
└──────────────────────────────┘
```

## 验收

### A. 构建 / 测试

- [ ] `swift build` 0 warning
- [ ] `swift test` 186 + P1 新增 + P2 新增（≥ 6 个桥接测试）
- [ ] EyeGuardDataBridge 100% 覆盖

### B. 运行时

- [ ] 启动后 3 秒内收起态开始显示连续时间递增
- [ ] 每秒更新一次，不卡顿
- [ ] 用眼 10/15/20 分钟颜色准时切换
- [ ] 点击"立即休息" → 进入休息覆盖层
- [ ] 休息中色点变蓝 eye.slash

### C. UI 截图

- `01-collapsed-green.png`（< 10 min）
- `02-collapsed-yellow.png`（10-15）
- `03-collapsed-red.png`（≥ 20）
- `04-expanded-panel.png`
- `05-break-in-progress.png`

### D. 回归

- [ ] 所有 P1 验收项重跑 ✅
- [ ] BreakScheduler 现有 186 测试全绿
- [ ] 既有休息倒计时、眼保健操、Dashboard 仍正常
