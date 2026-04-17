# UI Checklist

> 每次 Phase 验收时用。对比 Mio 原版的截图风格和 Eye Guard 实现的效果。

## 期望截图来源

从 `mio-guard/docs/screenshots/` 或 `mio-guard/marketing/` 抓原版 Mio 的刘海 UI 作为风格参考，放到 `.island_merge/screenshots/expected/`.

## Phase 1 — Notch Shell

| # | 文件 | 场景 | 验收点 |
|---|------|------|--------|
| 1.1 | `actual/phase-1/01-boot-collapsed.png` | 启动 2s 后 | 刘海区域**完全透明**；菜单栏图标可见 |
| 1.2 | `actual/phase-1/02-hover-expanded.png` | 鼠标悬停刘海 | 面板展开；占位 "Hello Notch"；圆角柔和 |
| 1.3 | `actual/phase-1/03-click-expanded.png` | 点击刘海 | 同 1.2 但激活（轻微高亮） |
| 1.4 | `actual/phase-1/04-click-outside-closes.png` | 面板外 click | 面板已关闭；点击穿透到桌面 |

## Phase 2 — 护眼数据

| # | 文件 | 场景 | 验收点 |
|---|------|------|--------|
| 2.1 | `01-collapsed-green.png` | 用眼 < 10 min | 绿色小点 + `00:08` |
| 2.2 | `02-collapsed-yellow.png` | 用眼 12 min | 黄色小点 + `00:12` |
| 2.3 | `03-collapsed-red.png` | 用眼 20 min | 红色 + `!` |
| 2.4 | `04-expanded-panel.png` | 展开 | 健康评分 + 倒计时 + 按钮 |
| 2.5 | `05-break-in-progress.png` | 休息中 | 🔵 eye.slash + 倒计时 |

## Phase 3 — 模式切换

| # | 文件 | 场景 |
|---|------|------|
| 3.1 | `01-mode-apu.png` | Apu 精灵可见，Notch 不可见 |
| 3.2 | `02-mode-notch.png` | Notch 可见，Apu 不可见 |
| 3.3 | `03-switch-animation.mov` | 2 秒 spring 切换录屏 |
| 3.4 | `04-preferences-mode-picker.png` | Preferences 分段控件 |

## Phase 4 — 休息流

| # | 文件 | 场景 |
|---|------|------|
| 4.1 | `01-pop-prebreak.png` | Notch pop 横幅 |
| 4.2 | `02-expanded-with-actions.png` | 立即休息 / 延后按钮 |
| 4.3 | `03-exercise-fullscreen.png` | 眼保健操全屏 |
| 4.4 | `04-break-countdown-collapsed.png` | 剩余时间收起态 |
| 4.5 | `05-pop-completion.png` | 休息完成庆祝 |

## Phase 5 — 打磨

| # | 文件 | 场景 |
|---|------|------|
| 5.1 | `01-hero-notch.png` | 首屏宣传图 |
| 5.2 | `02-hero-apu.png` | 精灵宣传图 |
| 5.3 | `03-mode-switch.gif` | 切换 GIF |
| 5.4 | `04-break-flow.gif` | 完整休息流 GIF |
| 5.5 | `05-preferences.png` | Preferences 完整 |
| 5.6 | `06-multi-screen.png` | 多屏截图 |

## 对比标准

Agent 交付截图后，PM 核对：

1. **画面完整性**：要求的元素都在吗
2. **对齐**：刘海水平居中？底部齐菜单栏？
3. **颜色**：色点颜色分级对吗？Material 模糊自然吗？
4. **文字**：字号、字体、间距合理？
5. **无穿帮**：没有 debug 文字、没有黑白占位？

## 截图收集方式

Agent 可以选择：
1. 手动截图（cmd+shift+4）然后 `cp` 进 `actual/phase-N/`
2. 或代码里加 debug snapshot：用 `ImageRenderer` 截 SwiftUI view

PM 也要**亲自截图**验证，不信任 Agent 单方面的"已完成"。
