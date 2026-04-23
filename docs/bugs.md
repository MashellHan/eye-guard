# Bug List

> 记录待处理 bug，按优先级逐个处理。处理时用 `/feature` 走 dev→review→test 流程。

记录时间：2026-04-23

## 待处理

### #1 Break 页面透明度过高，白色背景下文字不可读
- **现象**：break overlay 在白色背景上显示时，文字对比度不足，看不清
- **可能位置**：`EyeGuard/Sources/Notifications/BreakOverlayView.swift`
- **修复方向**：降低背景透明度 / 加深色 scrim / 文字加描边或阴影
- **验收**：白底、深底、彩色壁纸三种背景下文字都清晰可读（WCAG AA ≥ 4.5:1）

### #2 Break 结束时倒计时语音重复播放两次
- **现象**：break 结束播报触发了两次
- **可能位置**：语音播报订阅了重复事件 / 监听器没去重 / SwiftUI view 重建导致重复触发
- **修复方向**：定位重复触发点，加幂等保护或正确的取消订阅
- **验收**：完整跑一次 break，倒计时结束语音只响 1 次

### #3 Notch Island 上 "Take a Break" 点击无反应，且倒计时会停在 00:00
- **现象**：点击 island 上的 take a break 按钮没响应；倒计时跑到 00:00 后卡住不进入 break
- **可能位置**：`EyeGuard/Sources/Notch/Views/...` + `EyeGuardDataBridge` 事件透传
- **修复方向**：检查 button action 是否正确连到 BreakScheduler；倒计时归零的 transition 是否被某条件挡住
- **验收**：点击立即进入 break；倒计时归零自动进入 break

### #4 点击"开始眼保健操"无反应
- **现象**：按钮点击后没有任何 UI 反馈和后续动作
- **可能位置**：眼保健操入口的 action handler / 路由
- **修复方向**：定位按钮 action，检查目标 view/controller 是否被正确启动
- **验收**：点击后进入眼保健操流程

## 已修复

（暂无）
