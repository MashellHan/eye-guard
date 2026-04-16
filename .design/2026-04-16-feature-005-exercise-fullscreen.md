# Feature Design: 眼保健操全屏模式

**Date:** 2026-04-16
**Status:** Ready
**Priority:** P1

---

## 需求

眼保健操当前以浮动小窗口（420×640）呈现。用户希望改为**全屏覆盖**，与 break 页面一致，避免被其他窗口干扰。

## 现状

```
当前:
  眼保健操 → MascotWindowController.showExerciseWindow()
           → NSWindow(420×640, .floating, borderless)
           → 居中浮动，可被遮挡

Break:
  休息弹窗 → OverlayWindow.showFullScreenOverlay()
           → NSWindow(screen.frame, CGShieldingWindowLevel, borderless)
           → 全屏覆盖所有屏幕，0.65 黑色半透明 + blur
```

## 设计

### 交互设计

参考 `FullScreenOverlayView` 的全屏样式：

```
┌─────────────────────────────────────────┐
│          (半透明深色背景 + blur)            │
│                                         │
│              🐸 阿普 mascot              │
│                                         │
│         👋 眼保健操时间到！                 │
│           Eye Exercise Time!             │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │                                 │    │
│  │    当前练习: 上下左右看            │    │
│  │    🕐 剩余 35 秒                 │    │
│  │                                 │    │
│  │    ← 向上看，保持3秒 →            │    │
│  │                                 │    │
│  │    ● ● ○ ○ ○  (步骤进度)         │    │
│  │                                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│        进度: 1/5 组  ████░░░░░░          │
│        眼睛健康分: 75/100                │
│                                         │
│              [跳过当前]                   │
│                                         │
│              跳过全部                     │
└─────────────────────────────────────────┘
```

### 实现方案

1. **复用 `OverlayWindowController.showFullScreenOverlay()` 的窗口创建逻辑** — 全屏覆盖所有屏幕，`CGShieldingWindowLevel`
2. **替换窗口内容** — 用新的 `ExerciseFullScreenView` 替代现有的 `ExerciseSessionView`
3. **保持卡片式内容** — 中心区域放练习内容卡片，外围是半透明 + blur 背景
4. **保留所有现有功能** — TTS 语音、步骤切换、countdown、skip

### 关键区别（vs break 全屏）

| 维度 | Break 全屏 | 眼保健操全屏 |
|------|-----------|------------|
| 背景 | 0.65 黑色 + blur | 同 |
| 内容 | 倒计时环 + 健康分 | 练习卡片 + 步骤指示 |
| ESC | mandatory 不可退出 | 可退出（跳过全部） |
| 时长 | 20s/5min | ~2.5min |
| 窗口级别 | CGShieldingWindowLevel | 同 |

### 要点

- MascotWindowController 中的 `showExerciseWindow()` 改为调用全屏逻辑
- 现有的 intro/exercising/completed 三个阶段保留，放在全屏容器中
- 需要修复 BUG-005（布局空白）和 BUG-006（音频同步）后再做全屏改造

## 变更文件

| File | Change |
|------|--------|
| `Sources/Exercises/ExerciseSessionView.swift` | 适配全屏布局（居中内容，去掉固定宽高） |
| `Sources/Mascot/MascotWindowController.swift` | `showExerciseWindow()` 改为全屏窗口 |
| `Sources/Notifications/OverlayWindow.swift` | 可选：提取通用全屏窗口创建方法 |

## 依赖

- BUG-005（布局空白）先修复
- BUG-006（音频同步）先修复
