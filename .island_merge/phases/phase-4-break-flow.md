# Phase 4 — Notch 驱动休息流 + 通知

> **目标**：把现有的休息通知、眼保健操流程接入 Notch。在 Notch 模式下：休息提醒不用独立弹窗，而是 Notch **pop** 动画 + 打字机动画文字；点击进入眼保健操全屏覆盖层。

## 前置

- Phase 3 ✅
- 现有 `EyeGuardOverlayManager` + `ExerciseSessionView` 保持不变

## 交付物

### 新增源码

```
EyeGuard/Sources/Notch/Views/
├── NotchPopBanner.swift         # pop 动画横幅（休息提示）
└── TypewriterText.swift         # 打字机动画文字

EyeGuard/Sources/Notch/Bridges/
└── NotchBreakFlowAdapter.swift  # 订阅 BreakScheduler 事件 → Notch UI
```

### 修改

- `NotchViewModel.swift` 增加 `pop(message: String)` 方法
- `EyeGuardOverlayManager.swift`（或等效）：当 `AppMode == .notch` 时，提醒改走 Notch pop，不弹 Banner
- 休息中 Notch 收起态显示剩余时间

## 休息流（Notch 模式）

```
用眼 20 分钟 → BreakScheduler 触发 pre-break
  → Notch pop (1.8s 展开横幅) 打字："该休息了 💛"
  → 用户 hover/click Notch → 展开面板
     ├─ [立即休息] → 进入 ExerciseSessionView 全屏覆盖
     └─ [延后 5 分钟] → Notch 收起 + 5 分钟后再 pop
  → 休息期间 Notch 收起态：
     🔵 [eye.slash] 剩余 00:45
  → 休息完成 → Notch pop："很棒！继续加油 ✨"
```

## 验收

### A. 构建 / 测试

- [ ] `swift test` 全绿
- [ ] E2E 测试：模拟 20 分钟用眼（可加速） → 验证 Notch pop 触发

### B. 运行时

- [ ] 到达 20 分钟，Notch pop 准时触发（±1s）
- [ ] 打字机动画每字符约 40ms
- [ ] 点击"立即休息" → 眼保健操全屏启动
- [ ] 延后按钮 5 分钟后重新 pop
- [ ] 休息中 Notch 收起态剩余时间每秒递减
- [ ] Apu 模式切换到 Notch 后，旧的通知路径不再触发

### C. UI 截图

- `01-pop-prebreak.png`
- `02-expanded-with-actions.png`
- `03-exercise-fullscreen.png`
- `04-break-countdown-collapsed.png`
- `05-pop-completion.png`

### D. 回归

- Apu 模式仍然用原来的 FullScreenOverlay 走通休息流
- 所有 P1-P3 验收项
- 186 + 新增测试全部通过
