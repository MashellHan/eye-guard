# Phase 5 详细规格：Notch 护眼面板

## 概述

Eye Guard 模式下 Notch 展开后显示完整的护眼信息面板。这是合并后最有辨识度的 UI。

---

## Notch 收起状态 (Closed)

在 Notch 左右两翼显示简要信息：

```
[阿普😊]  ████████████  [2h35m 🟢]
  左翼                     右翼
```

### 左翼：阿普 Mini
- 使用 ApuMiniView（30pt）
- 表情根据 healthScore 变化
- 瞳孔跟随鼠标

### 右翼：连续使用时间
- 格式：`Xh Xm` 或 `Xm`（不足 1 小时不显示 h）
- 颜色圆点随时间变化：
  - `< 20min` → 🟢 绿
  - `20-45min` → 🔵 蓝  
  - `45-60min` → 🟡 橙
  - `> 60min` → 🔴 红 + pulse 动画

### 实现位置
修改 `NotchViewModel` 的 `closedContent`，根据 `ModeManager.currentMode` 渲染不同内容。

---

## Notch 展开状态 (Opened)

### Eye Guard Mode 完整面板

```
┌──────────────────────────────────────────────────┐
│              [阿普 30pt]  ████████               │
│──────────────────────────────────────────────────│
│                                                  │
│  🖥  已连续使用屏幕                               │
│       2h 35m                                     │
│  ████████████████████░░░░░ (75%)                 │
│  下次休息: 微休息 还剩 4m 32s                      │
│                                                  │
│──────────────────────────────────────────────────│
│                                                  │
│  健康评分                                        │
│  ┌──────────────────────────────┐                │
│  │  78/100  🟢 良好             │                │
│  │  休息 ██████░░  6/8          │                │
│  │  姿势 ████████  8/10         │                │
│  │  运动 ████░░░░  3/10         │                │
│  └──────────────────────────────┘                │
│                                                  │
│  💡 护眼小贴士                                    │
│  "每20分钟看20英尺外20秒，预防视疲劳"              │
│                                                  │
│──────────────────────────────────────────────────│
│  [📊 Dashboard]  [🏋 做操]  [📄 日报]            │
│──────────────────────────────────────────────────│
│  [⚙ 设置]                    [切换 Island 模式]  │
└──────────────────────────────────────────────────┘
```

### 各区域数据源

| 区域 | 数据源 | 刷新频率 |
|------|--------|----------|
| 连续使用时间 | `EyeGuardModule.currentSessionDuration` | 每秒 |
| 进度条 | `currentSessionDuration / nextBreakInterval` | 每秒 |
| 下次休息 | `EyeGuardModule.nextBreakIn` | 每秒 |
| 健康评分 | `EyeGuardModule.healthScore` | 休息后更新 |
| 护眼小贴士 | `TipDatabase.randomTip()` | 展开时随机 |

### 进度条颜色

```swift
var progressColor: Color {
    let ratio = currentSessionDuration / maxInterval
    switch ratio {
    case ..<0.5:  return .green
    case ..<0.75: return .blue
    case ..<0.9:  return .orange
    default:      return .red
    }
}
```

---

## Dual Mode 面板

Notch 展开后分两列：

```
┌──────────────────────────────────────────────────┐
│       [阿普]       ████████       [🐱]           │
│──────────────────────────────────────────────────│
│  ┌── Eye Guard ──┐  │  ┌── Island ──────────┐   │
│  │ 连续 2h 35m   │  │  │ Session 1         │   │
│  │ ██████░░ 75%  │  │  │ 🟢 Processing     │   │
│  │ 休息: 4m32s   │  │  │ Read src/app.ts   │   │
│  │               │  │  │                   │   │
│  │ 健康: 78 🟢   │  │  │ Session 2         │   │
│  │               │  │  │ 🟡 Waiting        │   │
│  └───────────────┘  │  └───────────────────┘   │
│──────────────────────────────────────────────────│
│  [📊] [🏋] [⚙]           [切换模式]             │
└──────────────────────────────────────────────────┘
```

### 宽度分配

```swift
GeometryReader { geo in
    HStack(spacing: 8) {
        eyeGuardColumn
            .frame(width: geo.size.width * 0.4)
        
        Divider()
        
        islandColumn
            .frame(width: geo.size.width * 0.55)
    }
}
```

Eye Guard 列窄一些（40%），因为信息密度低于 Island 的会话列表。

---

## SwiftUI 视图结构

```
NotchContentView (existing)
├── mode == .island → InstancesView (existing MioIsland)
├── mode == .eyeGuard → EyeGuardNotchView (NEW)
│   ├── ContinuousTimeSection
│   ├── HealthScoreSection
│   ├── TipSection
│   └── ActionButtonsSection
└── mode == .dual → DualModeNotchView (NEW)
    ├── EyeGuardCompactColumn
    └── IslandCompactColumn
```

### 新增文件

| 文件 | 行数估计 | 说明 |
|------|----------|------|
| `UI/Views/EyeGuard/EyeGuardNotchView.swift` | ~200 | 完整护眼面板 |
| `UI/Views/EyeGuard/ContinuousTimeSection.swift` | ~80 | 连续时间 + 进度条 |
| `UI/Views/EyeGuard/HealthScoreSection.swift` | ~100 | 评分 + 分项 |
| `UI/Views/EyeGuard/EyeGuardCompactColumn.swift` | ~60 | Dual 模式精简版 |
| `UI/Views/DualModeNotchView.swift` | ~50 | Dual 布局容器 |
